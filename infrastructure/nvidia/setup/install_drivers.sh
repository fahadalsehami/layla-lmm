# infrastructure/nvidia/setup/install_drivers.sh
#!/bin/bash

set -e

echo "Installing NVIDIA Drivers and CUDA Toolkit..."

# Variables
CUDA_VERSION="11.8.0"
DRIVER_VERSION="535.54.03"
CUDNN_VERSION="8.9.3.28"
TENSORRT_VERSION="8.5.3.1"

# Install necessary packages
apt-get update
apt-get install -y \
    build-essential \
    gcc \
    make \
    dkms \
    linux-headers-$(uname -r)

# Download and install NVIDIA drivers
wget https://us.download.nvidia.com/tesla/${DRIVER_VERSION}/NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run
chmod +x NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run
./NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run --silent --driver

# Install CUDA Toolkit
wget https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/cuda_${CUDA_VERSION}_linux.run
chmod +x cuda_${CUDA_VERSION}_linux.run
./cuda_${CUDA_VERSION}_linux.run --silent --toolkit

# Install cuDNN
echo "Installing cuDNN..."
wget https://developer.download.nvidia.com/compute/cudnn/secure/8.9.3/local_installers/11.8/cudnn-linux-x86_64-8.9.3.28_cuda11-archive.tar.xz
tar -xvf cudnn-linux-x86_64-8.9.3.28_cuda11-archive.tar.xz
cp -P cuda/include/* /usr/local/cuda/include/
cp -P cuda/lib64/* /usr/local/cuda/lib64/

# Install TensorRT
echo "Installing TensorRT..."
wget https://developer.nvidia.com/compute/tensorrt/secure/8.5.3/local_repos/nv-tensorrt-local-repo-ubuntu2204-8.5.3-cuda-11.8_1.0-1_amd64.deb
dpkg -i nv-tensorrt-local-repo-ubuntu2204-8.5.3-cuda-11.8_1.0-1_amd64.deb
apt-get update
apt-get install -y tensorrt

# Configure environment variables
cat >> /etc/environment << EOF
CUDA_HOME=/usr/local/cuda
PATH=\$PATH:/usr/local/cuda/bin
LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/cuda/lib64
EOF