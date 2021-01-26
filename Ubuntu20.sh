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
cmake-data \
cmake-qt-gui \

libssl-dev \
python3-pip \
gperf \
ros-noetic-rtabmap-ros \
k4a-tools \
libk4a1.4 \
libk4a1.4-dev \
libclang-dev \
libgmp3-dev \
liblapack-dev \
libopenblas-base \
libmpfr-dev \
libgdal-devlibgtsam-dev \
libgtsam-unstable-dev \
libnss3-dev \
libsuitesparse-dev \


sudo -H pip3 install -U jetson-stats

# PCL Qt5 dependencies: 
# Qt5::Concurrent Qt5::OpenGL Qt5::Widgets

# VTK Qt5 dependencies:
# Qt5::Gui Qt5::Sql Qt5::Widgets PyQt5

# OpenCV Qt5 dependencies:
# Qt5::Concurrent Qt5::Core Qt5::Gui Qt5::Test Qt5::Widgets 

# RtabMap Qt5 dependencies:
# Qt5::Core Qt5::Gui Qt5::PrintSupport Qt5::Svg Qt5::Widgets 

# ALL dependencies:
# Qt5::Core Qt5::Concurrent Qt5::Gui Qt5::OpenGL Qt5::PrintSupport Qt5::Sql Qt5::Svg Qt5::Test Qt5::Widgets

# Compile and install the needed submodules:
# https://forum.qt.io/topic/71651/how-to-compile-only-a-minimum-set-of-modules/8
git clone https://code.qt.io/qt/qt5.git --branch 5.15 && cd qt5
git submodule update --init --recursive
./configure -prefix /usr/local/qt5 -opensource -confirm-license -nomake tests -nomake examples -opengl desktop
cd ..

# qt5core
mkdir qt5core && cd qt5core
make module-qtcore-install_subtargets
qmake -r; make -j$(($(nproc) - 2)) clean
