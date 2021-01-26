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

# Install newest Cuda
# https://www.pugetsystems.com/labs/hpc/How-To-Install-CUDA-10-1-on-Ubuntu-19-04-1405/

sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt update
sudo apt upgrade
sudo apt-get install dkms build-essential libnvidia-common-460

# https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=sbsa&compilation=compilation_native&target_distro=Ubuntu&target_version=2004
wget https://developer.download.nvidia.com/compute/cuda/11.2.0/local_installers/cuda_11.2.0_460.27.04_linux_sbsa.run
sudo sh cuda_11.2.0_460.27.04_linux_sbsa.run # accept (Eula) --> disable driver --> install --> dont update symlink

# PCL Qt5 dependencies:
# Qt5::Widgets
# Qt5::OpenGL ??
# QT5_WRAP_UI
# QT5_WRAP_CPP

# VTK Qt5 dependencies:
# Qt5::Widgets
# Qt5::Gui
# Qt5::Sql
# PyQt5

# OpenCV Qt5 dependencies:
# Qt5::Core 
# Qt5::Gui 
# Qt5::Widgets 
# Qt5::Test 
# Qt5::Concurrent

# RtabMap Qt5 dependencies:
# Qt5::Widgets 
# Qt5::Core 
# Qt5::Gui 
# Qt5::Svg
