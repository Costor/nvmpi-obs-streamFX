#!/bin/bash

# set directory where you want to build everything
bd=~/nvmpi-obs

echo "this script will build obs with streamfx and nvmpi integration"
echo "it is written for nVidia Jetson Nano with Ubuntu 20.04"
echo "it is tested with OBS 27, StreamFX 0.11.0 and ffmpeg n4.2.5"
echo "the build directory is $bd"

if [ ! -d $bd ]; then
  echo "directory $bd does not exist, try to make it"
  mkdir $bd
  if [ ! -d $bd ]; then
    echo "could not create directory $bd"
    exit
  fi
fi

echo "installation of libs for full build of ffmpeg, obs and streamfx"
sudo apt build-dep -y ffmpeg obs-studio
sudo apt install -y libpci-dev qtbase5-private-dev clang clang-tidy clang-format

export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

echo "download, build and install libaom"
cd $bd
git clone https://aomedia.googlesource.com/aom
cd aom
mkdir build
cd build
cmake ..
make -j$(nproc)
sudo make install

echo "download, build and install jetson-ffmpeg"
cd $bd
git clone https://github.com/jocover/jetson-ffmpeg.git
cd jetson-ffmpeg
mkdir build
cd build
cmake ..
make -j$(nproc)
sudo make install
sudo ldconfig

echo "download, build and install ffmpeg (note : the build process take a while)"
cd $bd
git clone git://source.ffmpeg.org/ffmpeg.git -b release/4.2 --depth=1
cd ffmpeg
wget https://github.com/jocover/jetson-ffmpeg/raw/master/ffmpeg_nvmpi.patch
git apply ffmpeg_nvmpi.patch
./configure --enable-nvmpi --extra-cxxflags=-fPIC --enable-shared
make -j$(nproc)
sudo make install
sudo ldconfig

echo "download obs and streamfx"
cd $bd
git clone --recursive https://github.com/obsproject/obs-studio.git
cd obs-studio/UI/frontend-plugins
git submodule add 'https://github.com/Xaymar/obs-StreamFX.git' streamfx
git submodule update --init --recursive
echo "add_subdirectory(streamfx)" >> CMakeLists.txt

echo "download this git and patch streamfx"
cd $bd
git clone https://github.com/Costor/nvmpi-obs-streamFX
cd nvmpi-obs-streamFX
git checkout StreamFX-0.11.0
cp nvmpi_* $bd/obs-studio/UI/frontend-plugins/streamfx/source/encoders/handlers
git apply streamfx.patch --unsafe-paths --directory=$bd/obs-studio/UI/frontend-plugins/streamfx

echo "build and install obs"
cd $bd/obs-studio
mkdir build
cd build
cmake -DUNIX_STRUCTURE=1 -DCMAKE_INSTALL_PREFIX=/usr/local -DENABLE_PIPEWIRE=OFF -DBUILD_BROWSER=OFF -DCMAKE_CXX_FLAGS="-fPIC" ..
make -j$(nproc)
sudo make install
