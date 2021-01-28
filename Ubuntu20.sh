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
apt-utils \
build-essential \
checkinstall \
cmake-data=3.19.2-0kitware1ubuntu20.04.1 \
cmake \
cmake-qt-gui \
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
libmpfr-dev \
libnss3-dev \
libssl-dev \
libvulkan-dev \
libxkbcommon-dev \
nano \
python3-pip

sudo -H pip3 install -U jetson-stats

cups (printsupport) + gtk+(qtWidgets) wayland client library(qtwayland client/qtmultimedia) (miss nog eens compilen na gtk support door opencv)

# Compile and install the needed Modules:
# https://forums.developer.nvidia.com/t/recommended-c-compilation-flags-for-jetson-xavier/79452
# QMAKE_CXXFLAGS+="-c -MMD -pipe -std=gnu++17 -g -Wall -Werror -03"

# zlib
git clone https://github.com/madler/zlib
mkdir zlib/build && cd zlib/build
cmake ..
make -j$(($(nproc) - 2))
sudo make install

# libpng
# https://github.com/glennrp/libpng/tree/libpng16/contrib/arm-neon
git clone https://github.com/glennrp/libpng
mkdir libpng/build && cd libpng/build
.././configure --enable-arm-neon=check
make -j$(($(nproc) - 2))
sudo make install

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
git clone https://code.qt.io/qt/qt5.git --branch 5.15 && cd qt5
git submodule update --init --recursive qt3d qtbase qtconnectivity qtdeclarative qtimageformats qtlocation qtmultimedia qtquick3d qtquickcontrols2 qtscript qtscxml qtserialbus qttools qtwayland qtwebengine qtxmlpatterns
mkdir build && cd build
../configure -prefix /usr/local/qt5 -opensource -confirm-license -opengl desktop -nomake tests -nomake examples -skip qtmultimedia -skip qtwebengine -gui -widgets
make -j$(($(nproc) - 2))
sudo make install
make clean

echo "export PATH=/usr/local/qt5/bin:$PATH" >> ~/.bashrc
source ~/.bashrc
sudo ln -s /usr/local/qt5/bin/qmake /usr/lib/qt5/bin/qmake

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
make library JOBS=$(($(nproc) - 2))
sudo make install INSTALL=/usr/local

# eigen
git clone https://gitlab.com/libeigen/eigen.git
mkdir eigen/build && cd eigen/build
cmake ..
sudo make install

# ceres-solver
git clone https://ceres-solver.googlesource.com/ceres-solver
mkdir ceres-solver/build && cd ceres-solver/build
cmake .. \
-DBUILD_EXAMPLES:BOOL=OFF \
-DBUILD_TESTING:BOOL=OFF
make -j$(($(nproc) - 2))
sudo make install

# libQGLViewer
git clone https://github.com/GillesDebunne/libQGLViewer libQGLViewer-2.7.2
cd libQGLViewer-2.7.2/QGLViewer
qmake PREFIX=/user/local
make -j$(($(nproc) - 2))
sudo make install

# g2o (blas opties, miss zelfde blas als opencv gebruiken, dus nog een keer compilen)
git clone https://github.com/RainerKuemmerle/g2o
mkdir g2o/build && cd g2o/build
cmake .. \
-DG2O_FAST_MATH:BOOL=ON \
-DG2O_BUILD_BENCHMARKS:BOOL=OFF \
-DG2O_BUILD_EXAMPLES:BOOL=OFF
make -j$(($(nproc) - 2))
sudo make install

# VTK
git clone https://github.com/Kitware/VTK.git
mkdir VTK/build && cd VTK
git checkout v8.2.0
git submodule update --init --recursive
cd build && cmake .. \
-DCMAKE_BUILD_TYPE=Release \
-DCMAKE_INSTALL_PREFIX=/usr/local \
-DCMAKE_CUDA_COMPILER=/usr/local/cuda/bin/nvcc \
-DVTK_USE_CUDA:BOOL=ON \
-DBUILD_EXAMPLES:BOOL=OFF \
-DBUILD_TESTING:BOOL=OFF \
-DBUILD_SHARED_LIBS:BOOL=ON
make -j$(($(nproc) - 2))
sudo make install



# https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=sbsa&compilation=compilation_native&target_distro=Ubuntu&target_version=2004
wget https://developer.download.nvidia.com/compute/cuda/11.2.0/local_installers/cuda_11.2.0_460.27.04_linux_sbsa.run
sudo sh cuda_11.2.0_460.27.04_linux_sbsa.run # accept (Eula) --> disable driver --> install --> dont update symlink

cmake --build . --target core
make module-qtcore-install_subtargets

sudo apt install \

ros-noetic-rtabmap-ros \
libgmp3-dev \
liblapack-dev \
libopenblas-base \
libmpfr-dev \
libgdal-dev
libgtsam-dev \
libgtsam-unstable-dev \
libsuitesparse-dev \

