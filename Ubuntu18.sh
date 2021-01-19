#!/bin/bash

# InstallScript_AzureKinectMapping_NvidiaJetson_Ubuntu18
# Installation steps/script for mapping with Azure Kinect and Nvidia Jetson on Ubuntu 18 (Jetpack 4.4.1)

# add ROS repository
sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'

# add microsoft repository
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
echo 'deb [arch=arm64] https://packages.microsoft.com/ubuntu/18.04/multiarch/prod bionic main' | sudo tee /etc/apt/sources.list.d/microsoft-prod.list

# add GTSAM repository
sudo add-apt-repository ppa:borglab/gtsam-release-4.0

# after upgrade choose gdm3 not lightdm (because screen was gone after choosing lightdm on AGX)
sudo apt upgrade
sudo apt update
sudo apt install \
apt-utils \
build-essential \
checkinstall \
curl \
gperf \
python3-pip \
k4a-tools \
libk4a1.4 \
libk4a1.4-dev \
libcanberra-gtk-module \
libgtsam-dev \
libgtsam-unstable-dev \
libogg-dev \
libqt4-dev \
libssl-dev \
mlocate \
python-catkin-tools \
ros-melodic-libg2o \
ros-melodic-pcl-ros \
ros-melodic-imu-filter-madgwick \
ros-melodic-tf2-geometry-msgs \
ros-melodic-rtabmap-ros \

sudo -H pip3 install -U jetson-stats
sudo updatedb

# Add rules for Azure Kinect
sudo wget -O /etc/udev/rules.d/99-k4a.rules https://github.com/microsoft/Azure-Kinect-Sensor-SDK/raw/develop/scripts/99-k4a.rules

# Make directory for packages that need to be build
mkdir ~/Repos && cd ~/Repos

# CMake
git clone https://github.com/Kitware/CMake
mkdir CMake/build && cd CMake/build
../CMake/bootstrap && make -j$(($(nproc) - 2))
sudo checkinstall --pkgname cmake --pkgversion 3.19.2 --provides cmake -y

cd ../..

# libnabo (needed for libpointmatcher)
git clone git://github.com/ethz-asl/libnabo.git
mkdir libnabo/build
cd libnabo/build
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
make -j$(($(nproc) - 2))
sudo make install

cd ../..

# libpointmatcher
git clone https://github.com/ethz-asl/libpointmatcher
mkdir libpointmatcher/build
cd libpointmatcher/build
cmake ..
make -j$(($(nproc) - 2))
sudo make install

cd ../..

# get vtk6.3.0 files depending on Qt build with Qt4
wget "https://github.com/introlab/rtabmap/files/3457605/vtk6.3.0-arm64-qt4-libs-cmake.zip" -O vtk.zip
sudo unzip -j -d /usr/lib/aarch64-linux-gnu/ -o vtk.zip *.so*
sudo unzip -j -d /usr/lib/cmake/vtk-6.3/Modules/ -o vtk.zip *.cmake*
sudo rm /usr/lib/cmake/vtk-6.3/Modules/vtkGUISupportQtWebkit.cmake
sudo sed -i 's/;Qt5::[^;|"]*//g' /usr/lib/cmake/vtk-6.3/VTKTargets.cmake
sudo sed -i 's/^.*"Qt5::[^;]*"$|;Qt5::[^;|"]*|(?<=")Qt5::.*[;]//g' /usr/lib/cmake/vtk-6.3/VTKTargets-none.cmake

# creating new links
cd /usr/lib/aarch64-linux-gnu

sudo ln -sf libvtkGUISupportQtOpenGL-6.3.so.1 libvtkGUISupportQtOpenGL-6.3.so.6.3.0
sudo ln -sf libvtkGUISupportQt-6.3.so.1 libvtkGUISupportQt-6.3.so.6.3.0
sudo ln -sf libvtkRenderingQt-6.3.so.1 libvtkRenderingQt-6.3.so.6.3.0
sudo ln -sf libvtkGUISupportQtSQL-6.3.so.1 libvtkGUISupportQtSQL-6.3.so.6.3.0
sudo ln -sf libvtkViewsQt-6.3.so.1 libvtkViewsQt-6.3.so.6.3.0

sudo ln -s libvtkInteractionStyle-6.3.so.6.3.0 libvtkInteractionStyle-6.3.so.1
sudo ln -s libvtkRenderingOpenGL-6.3.so.6.3.0 libvtkRenderingOpenGL-6.3.so.1 
sudo ln -s libvtkRenderingCore-6.3.so.6.3.0 libvtkRenderingCore-6.3.so.1
sudo ln -s libvtkFiltersExtraction-6.3.so.6.3.0 libvtkFiltersExtraction-6.3.so.1
sudo ln -s libvtkCommonDataModel-6.3.so.6.3.0 libvtkCommonDataModel-6.3.so.1
sudo ln -s libvtkCommonCore-6.3.so.6.3.0 libvtkCommonCore-6.3.so.1

source /opt/ros/melodic/setup.bash

# RtabMap with Qt4
cd ~/Repos

git clone https://github.com/introlab/rtabmap.git
cd rtabmap/build
cmake -DBUILD_EXAMPLES=OFF -DRTABMAP_QT_VERSION=4 ..
make -j$(($(nproc) - 2))
sudo apt remove ros-melodic-rtabmap
sudo make install

wget -O ~/Documents/RTAB-Map/config.ini http://official-rtab-map-forum.67519.x6.nabble.com/file/n7187/config_k4a_icp_v3.ini
wget -O ~/.rtabmap/rtabmap.ini http://official-rtab-map-forum.67519.x6.nabble.com/file/n7187/config_k4a_icp_v3.ini

sudo ldconfig

# start and test RtabMap
rtabmap

# create catkin workspace and download ros packages
mkdir -p ~/catkin_ws/src && cd ~/catkin_ws/src
catkin init
cd .. && catkin build
cd src
git clone https://github.com/ChemicalNRG/Azure_Kinect_ROS_Driver.git
git clone https://github.com/ros-perception/image_transport_plugins.git --branch noetic-devel --single-branch
git clone https://github.com/ros-perception/image_common.git --branch noetic-devel --single-branch
git clone https://github.com/OAkyildiz/vision_opencv
git clone https://github.com/introlab/rtabmap_ros

# build the packages
cd ..
catkin build -j1 --cmake-args -DCATKIN_ENABLE_TESTING=False -DRTABMAP_QT_VERSION=4 -DCMAKE_BUILD_TYPE=Release

echo "source /opt/ros/melodic/setup.bash" >> ~/.bashrc
echo "source ~/catkin_ws/devel/setup.bash" >> ~/.bashrc
source ~/.bashrc

# test rtabmap_ros
