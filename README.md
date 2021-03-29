# nvmpi-streamFX-obs
nvidia nvmpi encoder for streamFX and obs-studio (e.g. for nvidia jetson. Requires nvmpi enabled ffmpeg / libavcodec)

# Purpose
This is a documentation plus the source files I created / modified in order to build a version of [obs-studio](https://obsproject.com) that uses the nvidia nvmpi hardware encoder available e.g. on the nvidia jetson series (at least on the jetson series, nvidia nvmpi replaces the well known nvenc hardware encoder).
It relies on the integration of [nvmpi into ffmpeg](https://github.com/jocover/jetson-ffmpeg) and on the [obs-StreamFX plugin](https://github.com/Xaymar/obs-StreamFX) to make the nvmpi hardware encoder available in obs-studio. 

To this end I had to add a handler for nvmpi to StreamFX which I provide here for the benefit of whoever wants to build nvmpi support into obs-StreamFX (it is essentially just a slightly modified copy of StreamFX's nvenc handler). 

# Limitations
This is not a maintained project, but documents the solution I built for me and am using as of February / March 2021 on nvidia jetson nano 4GB and Ubuntu 20.04 with the kind support of [Xaymar](https://github.com/Xaymar/obs-StreamFX/issues/470). 
It can not become part of the StreamFX package as least as long there is no maintainance which I cannot provide due to lack of capacity and resources. 

So as development of StreamFX, jetson-ffmpeg and obs-studio continue, you might be required to do modifications on your own. Also the nvmpi-into-ffmpeg integration is an ongoing effort where functional limitations may exist. 

No jetson specific dependencies have come to my attention, so it would probably work in other environments with nvmpi encoder hardware where an integration into ffmpeg / libavcodec exists.

# Documentation

## Prerequisite Steps
Using the built instruction provided with the packages (plus the remarks below) you first need to download, build and deploy a working version of

- [jetson-ffmpeg](https://github.com/jocover/jetson-ffmpeg)

- [obs-studio](https://github.com/obsproject/obs-studio) including the StreamFX plugin below:

 - [StreamFX](https://github.com/Xaymar/obs-StreamFX)

		
### Remarks on building ffmpeg:

- I used GCC/G++ version 8 for the compile as the nvidia cuda 10.2 provided with the jetson requires GCC/G++ 8
- I also found that the compiler flag -fPIC was required in the build configuration statement if on arm64/aarch64 Linux:
```
./configure --enable-nvmpi --extra-cxxflags=-fPIC --enable-shared
```
- In order to avoid conflicts with the ffmpeg standard package that ubuntu provides I left the installation prefix /usr/local/ as the installation default. This will install libavcodec.so etc into /usr/local/lib. However if there are other libav* versions in the system (e.g. from a standard ffmpeg  in /usr/lib) it is important to force the correct search order for these libraries e.g. by inserting /usr/local/bin at the beginning of the library search path LD_LIBRARY_PATH.
- You should test this ffmpeg as described in the building instructions to verify that nvmpi encoders work properly

### Remarks on building obs-studio with StreamFX:
	
- I used StreamFX as a frontend-plugin, i.e. put the StreamFX sources into ~/obs-studio/UI/frontend-plugins (assuming that ~/obs-studio holds the obs build environment)
- StreamFX requires C++17 so GCC/G++ 9 is required. (This poses no problem with cuda 10.2 as on Linux neither obs nor StreamFX compile cuda sources. Obs and StreamFX actually compiled with with GCC/G++ 8, however I experienced the [GCC 8 'filesystem' segfault bug](https://bugs.launchpad.net/ubuntu/+source/gcc-8/+bug/1824721)) 
- In order to avoid conflicts with the obs-studio standard package that ubuntu provides I chose /usr/local/ as the installation location for the self-built obs by modifying the option -DCMAKE_INSTALL_PREFIX=/usr/local in the cmake statement 
- Also in the cmake statement the option -DCMAKE_CXX_FLAGS="-fPIC" needed to be added (as with jetson-ffmpeg) for correctly linking in arm64/aarch64 Linux and GCC/G++.
- I have built obs with the Chromium Extension Framework CEF; no cross effects to nvmpi there as expected
- Obs sometimes complains about missing libraries libobs-frontend-api.so.0 or libobs-opengl.so.0. I cured this by creating links to libobs-frontend-api.so.0.0 resp. libobs-opengl.so.0.0 in /usr/local/bin

At this point the self build obs-studio will **not yet** offer nvidia nvmpi when checking in settings->output->output mode = advanced, but obs itself should work fine with software encoding, and StreamFX should show up in the obs menu. 

## Integrating nvmpi encoder into StreamFX and obs-studio

- The six source files nvmpi* form the nvmpi handler (analogously to StreamFX's nvenc handler). Place them in ~/obs-studio/UI/frontend-plugins/streamfx/source/encoders/handlers beside the nvenc* files.
- Search the file CMakeLists.txt for 'nvmpi' and transfer the lines over into ~/obs-studio/UI/frontend-plugins/streamfx/CMakeLists.txt, i.e. the build description of the current StreamFX, in an adequate way.
- In ~/obs-studio/UI/frontend-plugins/streamfx/source/encoders/encoder-ffmpeg.cpp the folowing two lines need to be added directly below the corresponding #includes for nvenc, i.e. below  '#include "handlers/nvenc_hevc_handler.hpp"':
```
#include "handlers/nvmpi_h264_handler.hpp" 
#include "handlers/nvmpi_hevc_handler.hpp"
```
- and two lines below should be added in function ffmpeg_manager::ffmpeg_manager() below the line '#ifdef ENABLE_ENCODER_FFMPEG_NVENC':
```
register_handler("h264_nvmpi", ::std::make_shared<handler::nvmpi_h264_handler>());
register_handler("hevc_nvmpi", ::std::make_shared<handler::nvmpi_hevc_handler>());
```
Then refresh the build system by re-doing the cmake step for obs-studio, and rebuild obs-studio. 
If everything went right nvmpi h264 and h265 will now be offered in obs when you choose settings->output->output mode = advanced. 

Enjoy!
 

### Footnote: Using obs with xrdp and VirtualGL

Obs-studio requires OpenGL support. If you access your Linux Desktop from remote (e.g. via xrdp or vnc), openGL support will be via software (MESA) or non-existent. I found that using [VirtualGL](www.virtualGL.org) obs-studio runs reasonably well in a remote xrdp session in the same LAN, see [xrdp forum](https://github.com/neutrinolabs/xrdp/issues/1697#issuecomment-806578753). 

