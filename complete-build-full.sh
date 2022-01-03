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
sudo apt install -y \
             build-essential \
             checkinstall \
             clang \
             clang-tidy \
             clang-format \
             cmake \
             git \
             libmbedtls-dev \
             libasound2-dev \
             libavcodec-dev \
             libavdevice-dev \
             libavfilter-dev \
             libavformat-dev \
             libavutil-dev \
             libcurl4-openssl-dev \
             libfdk-aac-dev \
             libfontconfig-dev \
             libfreetype6-dev \
             libgl1-mesa-dev \
             libjack-jackd2-dev \
             libjansson-dev \
             libluajit-5.1-dev \
             libpci-dev \
             libpulse-dev \
             libqt5x11extras5-dev \
             libspeexdsp-dev \
             libswresample-dev \
             libswscale-dev \
             libudev-dev \
             libv4l-dev \
             libvlc-dev \
             libx11-dev \
             libx264-dev \
             libxcb-shm0-dev \
             libxcb-xinerama0-dev \
             libxcomposite-dev \
             libxinerama-dev \
             pkg-config \
             python3-dev \
             qtbase5-dev \
             libqt5svg5-dev \
             swig \
             libxcb-randr0-dev \
             libxcb-xfixes0-dev \
             libx11-xcb-dev \
             libxcb1-dev \
             qtdeclarative5-dev \
             qtbase5-private-dev


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
./configure --enable-nvmpi --extra-cxxflags=-fPIC --enable-shared --extra-version=1ubuntu0.1 --toolchain=hardened --libdir=/usr/lib/aarch64-linux-gnu --incdir=/usr/include/aarch64-linux-gnu --arch=arm64 --enable-gpl --disable-stripping --enable-avresample --disable-filter=resample --enable-avisynth --enable-gnutls --enable-ladspa --enable-libaom --enable-libass --enable-libbluray --enable-libbs2b --enable-libcaca --enable-libcdio --enable-libcodec2 --enable-libflite --enable-libfontconfig --enable-libfreetype --enable-libfribidi --enable-libgme --enable-libgsm --enable-libjack --enable-libmp3lame --enable-libmysofa --enable-libopenjpeg --enable-libopenmpt --enable-libopus --enable-libpulse --enable-librsvg --enable-librubberband --enable-libshine --enable-libsnappy --enable-libsoxr --enable-libspeex --enable-libssh --enable-libtheora --enable-libtwolame --enable-libvidstab --enable-libvorbis --enable-libvpx --enable-libwavpack --enable-libwebp --enable-libx265 --enable-libxml2 --enable-libxvid --enable-libzmq --enable-libzvbi --enable-lv2 --enable-omx --enable-openal --enable-opencl --enable-opengl --enable-sdl2 --enable-libdc1394 --enable-libdrm --enable-libiec61883 --enable-chromaprint --enable-frei0r --enable-libx264 --enable-nonfree --enable-libfdk-aac
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
