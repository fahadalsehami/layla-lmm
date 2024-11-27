# infrastructure/nvidia/setup/setup_container_runtime.sh
#!/bin/bash

# Install NVIDIA Container Toolkit
curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey | \
  sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list
sudo apt-get update
sudo apt-get install -y nvidia-container-runtime

# Configure Docker
sudo mkdir -p /etc/docker
sudo cp nvidia-container-toolkit.conf /etc/docker/daemon.json
sudo systemctl restart docker

# Test NVIDIA Container Runtime
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
