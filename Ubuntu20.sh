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

# https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=sbsa&compilation=compilation_native&target_distro=Ubuntu&target_version=2004
wget https://developer.download.nvidia.com/compute/cuda/11.2.0/local_installers/cuda_11.2.0_460.27.04_linux_sbsa.run
sudo sh cuda_11.2.0_460.27.04_linux_sbsa.run # accept (Eula) --> disable driver --> install --> dont update symlink

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
libharfbuzz-dev \
libnss3-dev \
libvulkan-dev \
libxkbcommon-dev \
python3-pip

sudo -H pip3 install -U jetson-stats

cups + gtk+ ??

# Compile and install the needed Modules:
# https://forums.developer.nvidia.com/t/recommended-c-compilation-flags-for-jetson-xavier/79452

# Qt5
# https://forum.qt.io/topic/71651/how-to-compile-only-a-minimum-set-of-modules/8
# https://en.wikipedia.org/wiki/Qt_(software)#Programming_language_bindings
# PCL Qt5 dependencies: Qt5::Concurrent Qt5::OpenGL Qt5::Widgets
# VTK Qt5 dependencies: Qt5::Gui Qt5::Sql Qt5::Widgets PyQt5
# OpenCV Qt5 dependencies: Qt5::Concurrent Qt5::Core Qt5::Gui Qt5::Test Qt5::Widgets 
# RtabMap Qt5 dependencies: Qt5::Core Qt5::Gui Qt5::PrintSupport Qt5::Svg Qt5::Widgets 
# ALL dependencies: Qt5::Core Qt5::Concurrent Qt5::Gui Qt5::OpenGL Qt5::PrintSupport Qt5::Sql Qt5::Svg Qt5::Test Qt5::Widgets
# git submodule update --init <submodule>
# ./configure -help
# ./configure -list-features
# ninja <submodule>/all
# cmake --build . --target <submodule>
# make module-<submodule>-install_subtargets
# QMAKE_CXXFLAGS+="-c -MMD -pipe -std=gnu++17 -g -Wall -Werror -03"
# QtCore QtConcurrent QtGui QtOpenGL QtPrintSupport QtSql QtSvg QtTest QtWidgets QtWebEngine
# submodules in folders: qtbase qt3d qtconnectivity qtdeclarative qtgamepad qtimageformats qtlocation qtmultimedia qtquick3d qtquickcontrols2 qtscript qtscxml qtsensors qtserialbus qtserialport qtspeech qttools qtwayland qtwebengine qtxmlpatterns

git clone https://code.qt.io/qt/qt5.git --branch 5.15 && cd qt5
git submodule update --init --recursive qt3d qtbase qtconnectivity qtdeclarative qtimageformats qtlocation qtmultimedia qtquick3d qtquickcontrols2 qtscript qtscxml qtserialbus qttools qtwebengine qtxmlpatterns
mkdir build && cd build
../configure -prefix /usr/local/qt5 -opensource -confirm-license -opengl desktop -nomake tests -nomake examples -gui -widgets
make -j$(($(nproc) - 2))
make clean
sudo make install

cd ..

cmake --build . --target core
make module-qtcore-install_subtargets

sudo apt install \
libssl-dev \
ros-noetic-rtabmap-ros \
libgmp3-dev \
liblapack-dev \
libopenblas-base \
libmpfr-dev \
libgdal-dev
libgtsam-dev \
libgtsam-unstable-dev \
libsuitesparse-dev \

