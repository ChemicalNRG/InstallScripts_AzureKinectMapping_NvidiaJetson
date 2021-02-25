#!/bin/bash

# InstallScript_AzureKinectMapping_NvidiaJetson_Ubuntu20
# Installation steps/script for mapping with Azure Kinect and Nvidia Jetson on Ubuntu 20 (Jetpack 4.5.0)

# Install Jetpack 4.5.0 through Nvidia SDK Manager
# remote desktop: https://www.nomachine.com/download/download&id=116&s=ARM

# Remove chromium-browser or else you get errors while doing dist upgrade
sudo apt purge --auto-remove chromium-browser chromium-browser-l10n

# enable dist upgrade in 'Software & Updates --> Updates --> Notify me of a new Ubuntu version --> For any new version / For long-term support versions
# https://carlosedp.medium.com/upgrading-your-nvidia-jetson-xavier-nx-to-latest-ubuntu-focal-fossa-20-04-5e92ccc5a66
sudo do-release-upgrade -d -f DistUpgradeViewGtk3
sudo apt autoremove

# add ROS repository
sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'

# add microsoft repository
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
echo 'deb [arch=arm64] https://packages.microsoft.com/ubuntu/18.04/multiarch/prod bionic main' | sudo tee /etc/apt/sources.list.d/microsoft-prod.list
sudo apt-add-repository https://packages.microsoft.com/ubuntu/20.04/prod

# add GTSAM repository
sudo add-apt-repository ppa:borglab/gtsam-release-4.0

sudo apt install \
apt-file \
apt-utils \
build-essential \
checkinstall \
cmake-data=3.19.2-0kitware1ubuntu20.04.1 \
cmake \
cmake-qt-gui \
clang \
gperf \
k4a-tools \
libk4a1.4 \
libk4a1.4-dev \
libclang-dev \
libdbus-1-dev \
libfontconfig1-dev \
libgflags-dev \
libgmp-dev \
libgoogle-glog-dev \
libharfbuzz-dev \
libhdf5-dev \
libinput-dev \
libmpfr-dev \
libnss3-dev \
libssl-dev \
libvulkan-dev \
libxkbcommon-dev \
libxkbcommon-x11-dev \
nano \
ninja-build \
nodejs \
python3-pip

sudo -H pip3 install -U jetson-stats

# Compile and install the needed Modules:

# libusb
git clone https://github.com/libusb/libusb
./bootstrap.sh
make
sudo make install

cd ..

# zlib
git clone https://github.com/madler/zlib
mkdir zlib/build && cd zlib/build
cmake ..
make -j$(($(nproc) - 2))
sudo make install

cd ../..

# Qt5
# https://forum.qt.io/topic/71651/how-to-compile-only-a-minimum-set-of-modules/8
# https://en.wikipedia.org/wiki/Qt_(software)#Programming_language_bindings

# PCL Qt5 dependencies: Qt5::Concurrent Qt5::OpenGL Qt5::Widgets
# VTK Qt5 dependencies: Qt5::Gui Qt5::Sql Qt5::Widgets PyQt5
# OpenCV Qt5 dependencies: Qt5::Concurrent Qt5::Core Qt5::Gui Qt5::Test Qt5::Widgets 
# RtabMap Qt5 dependencies: Qt5::Core Qt5::Gui Qt5::PrintSupport Qt5::Svg Qt5::Widgets 
# ALL dependencies: Qt5::Core Qt5::Concurrent Qt5::Gui Qt5::OpenGL Qt5::PrintSupport Qt5::Sql Qt5::Svg Qt5::Test Qt5::Widgets

# ./configure -help / -list-features / -list-libraries
# ninja <submodule>/all / cmake --build . --target <submodule> / make module-<submodule>-install_subtargets

# QtCore QtConcurrent QtGui QtOpenGL QtPrintSupport QtSql QtSvg QtTest QtWidgets QtWebEngine
# submodules in folders: qtbase qt3d qtconnectivity qtdeclarative qtgamepad qtimageformats qtlocation qtmultimedia qtquick3d qtquickcontrols2 qtscript qtscxml qtsensors qtserialbus qtserialport qtspeech qttools qtwebengine qtxmlpatterns
# https://github.com/grpc/grpc/issues/11655
# git submodule update --init --recursive qt3d qtbase qtconnectivity qtdeclarative qtimageformats qtlocation qtquick3d qtquickcontrols2 qtscript qtscxml qtserialbus qttools qtx11extras qtxmlpatterns
# makeQT script also uses the -qt-xcb     https://www.cfd-online.com/Forums/openfoam-installation/197626-paraview-cmake-error.html
# git checkout 5.15.1

git clone https://code.qt.io/qt/qt5.git --branch 5.14 && cd qt5
git submodule update --init --recursive
mkdir build && cd build
sudo apt autoremove *libopencv*-dev
../configure -prefix /usr/local -opensource -confirm-license -nomake tests -nomake examples -opengl desktop -skip qtdocgallery -skip qtlocation -skip qtvirtualkeyboard -skip qtmultimedia -skip qtquickcontrols
sudo make -j$(($(nproc) - 2)) QT_DEBUG_PLUGINS=1
sudo make install

cd ../..

sudo nano /usr/local/cuda-10.2/include/crt/host_config.h
# change:
#if __GNUC__ > 8
#error -- unsupported GNU version! gcc versions later than 8 are not supported!
#endif /* __GNUC__ > 8 */
# to:
#if __GNUC__ > 9
#error -- unsupported GNU version! gcc versions later than 9 are not supported!
#endif /* __GNUC__ > 9 */

# https://forums.developer.nvidia.com/t/cublas-for-10-1-is-missing/71015/5
sudo ln -s /usr/lib/aarch64-linux-gnu/libcublas.so.10.2.2.89 /usr/local/cuda-10.2/lib64/libcublas.so

# suitesparse
git clone https://github.com/DrTimothyAldenDavis/SuiteSparse
cd SuiteSparse
make library -j2 INSTALL=/usr/local
sudo make install INSTALL=/usr/local
sudo apt install libsuitesparse-dev

# library
# DESTDIR=/work/qt-prefix make install

cd ../..

# eigen
git clone https://gitlab.com/libeigen/eigen.git
mkdir eigen/build && cd eigen/build
cmake .. \
-DEIGEN_TEST_NOQT=1 \
-DEIGEN_TEST_NEON64=ON \
-DEIGEN_TEST_CXX11=ON \
-DEIGEN_TEST_CUDA=ON \
-DEIGEN_TEST_CUDA_CLANG=ON \
-DEIGEN_TEST_OPENGL=ON \
-DOpenGL_GL_PREFERENCE=GLVND \
-DEIGEN_CUDA_COMPUTE_ARCH:STRING=72 \
-DEIGEN_TEST_OPENMP=ON
sudo make install

cd ../..

# ceres-solver
git clone https://ceres-solver.googlesource.com/ceres-solver
mkdir ceres-solver/build && cd ceres-solver/build
cmake .. \
-DBUILD_EXAMPLES:BOOL=OFF \
-DBUILD_TESTING:BOOL=OFF \
-DSUITESPARSE:BOOL=ON
make -j$(($(nproc) - 2))
sudo make install

cd ../..

# libQGLViewer
git clone https://github.com/GillesDebunne/libQGLViewer libQGLViewer-2.7.2
cd libQGLViewer-2.7.2/QGLViewer
qmake PREFIX=/user/local
make -j$(($(nproc) - 2))
sudo make install

cd ../..

# g2o
git clone https://github.com/RainerKuemmerle/g2o
mkdir g2o/build && cd g2o/build
cmake .. \
-DG2O_FAST_MATH:BOOL=ON \
-DG2O_BUILD_BENCHMARKS:BOOL=OFF \
-DG2O_BUILD_EXAMPLES:BOOL=OFF
make -j$(($(nproc) - 2))
sudo make install

cd ../..

# VTK
git clone https://github.com/Kitware/VTK.git
mkdir VTK/build && cd VTK
git checkout v8.2.0
git submodule update --init --recursive
cd build && cmake .. \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_INSTALL_PREFIX=/usr/local \
-DBUILD_EXAMPLES=OFF \
-DBUILD_TESTING=OFF \
-DBUILD_SHARED_LIBS=ON \
-DVTK_USE_SYSTEM_PNG=ON \
-DVTK_LEGACY_REMOVE=ON \
-DVTK_Group_Qt=ON \
-DVTK_QT_VERSION=5
make -j$(($(nproc) - 2))
sudo make install

cd ../..

# opencv4.5.1
mkdir opencv451 && cd opencv451
git clone https://github.com/opencv/opencv
git clone https://github.com/opencv/opencv_contrib
mkdir build && cd build
cmake ../opencv \
-DCMAKE_BUILD_TYPE=RELEASE \
-DCMAKE_INSTALL_PREFIX=/usr/local \
-DOPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules \
-DOPENCV_ENABLE_NONFREE=ON \
-DINSTALL_C_EXAMPLES=OFF \
-DINSTALL_PYTHON_EXAMPLES=OFF \
-DBUILD_PERF_TESTS=OFF \
-DBUILD_EXAMPLES=OFF \
-DBUILD_TESTS=OFF \
-DBUILD_DOCS=OFF \
-DCUDA_ARCH_BIN=7.2 \
-DCUDA_ARCH_PTX="" \
-DENABLE_FAST_MATH=ON \
-DCUDA_FAST_MATH=ON \
-DWITH_CUDA=ON \
-DWITH_CUDNN=ON \
-DWITH_CUBLAS=ON \
-DWITH_TBB=ON \
-DWITH_V4L=ON \
-DWITH_QT=ON \
-DWITH_OPENGL=ON
make -j$(($(nproc) - 2))
sudo apt remove *libopencv*-dev
sudo apt autoremove
sudo make install

sudo apt remove libgtk2.0-dev libcanberra-gtk* libgtk-3-dev  # will remove all gtk from jetson (more performance)

sudo apt-get install \
libgtk3-nocsd0 \
libxvidcore-dev libx264-dev  \
v4l-utils libvorbis-dev libxine2-dev \
libfaac-dev libmp3lame-dev \
libopencore-amrnb-dev libopencore-amrwb-dev \
libopenblas-dev libatlas-base-dev protobuf-compiler \
libprotobuf-dev

cd ../..

# libnabo (needed for libpointmatcher)
git clone git://github.com/ethz-asl/libnabo.git
mkdir libnabo/build && cd libnabo/build
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
make -j$(($(nproc) - 2))
sudo make install

cd ../..

sudo apt install libboost-all-dev

# libpointmatcher
git clone https://github.com/ethz-asl/libpointmatcher
mkdir libpointmatcher/build && cd libpointmatcher/build
cmake ..
make -j$(($(nproc) - 2))
sudo make install

cd ../..

sudo apt install \
libflann-dev \
libglew-dev \
libopenni-dev \
libopenni2-dev \
libqhull-dev

# pcl (arch=native)
git clone https://github.com/larshg/pcl
mkdir pcl/build && cd pcl/build
cmake .. \
-DCUDA_ARCH_BIN=7.2 \
-DBUILD_CUDA=ON \
-DBUILD_GPU=ON \
-DBUILD_gpu_surface:BOOL=ON
make -j$(($(nproc) - 2))
sudo make install

pcl::getAngle3D
pcl::Indices

from source:
libusb
magma


cd ../..

# Build RtabMap
git clone https://github.com/introlab/rtabmap
cd rtabmap/build
cmake -DBUILD_EXAMPLES=OFF -DRTABMAP_QT_VERSION=5 ..
make -j$(($(nproc) - 2))
make -j1 VERBOSE=1
sudo make install


sed -i 's/QVTKWidget/QVTKOpenGLWidget/g' rtabmap/guilib/include/rtabmap/gui/CloudViewer.h
sed -i 's/QVTKWidget/QVTKOpenGLWidget/g' rtabmap/guilib/src/CloudViewer.cpp
sed -i 's/ADD_SUBDIRECTORY( ExtractObject )/# ADD_SUBDIRECTORY( ExtractObject )/g' rtabmap/tools/CMakeLists.txt

util3d_correspondences.cpp
rtabmap/corelib/src/util3d_surface.cpp



# https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=sbsa&compilation=compilation_native&target_distro=Ubuntu&target_version=2004
wget https://developer.download.nvidia.com/compute/cuda/11.2.0/local_installers/cuda_11.2.0_460.27.04_linux_sbsa.run
sudo sh cuda_11.2.0_460.27.04_linux_sbsa.run # accept (Eula) --> disable driver --> install --> dont update symlink

sudo apt install \

ros-noetic-rtabmap-ros \
libgmp3-dev \
liblapack-dev \
libopenblas-base \
libmpfr-dev \
libgdal-dev
libgtsam-dev \
libgtsam-unstable-dev \

-prefix /usr/local/qt5
echo "export PATH=/usr/local/qt5/bin:$PATH" >> ~/.bashrc
source ~/.bashrc

[ 10%] Linking CXX executable ../../../bin/rtabmap-extractObject
/usr/bin/ld: cannot find -lvtkGUISupportQt
collect2: error: ld returned 1 exit status
make[2]: *** [tools/ExtractObject/CMakeFiles/extractObject.dir/build.make:192: ../bin/rtabmap-extractObject] Error 1
make[1]: *** [CMakeFiles/Makefile2:950: tools/ExtractObject/CMakeFiles/extractObject.dir/all] Error 2
make[1]: *** Waiting for unfinished jobs....
