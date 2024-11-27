# infrastructure/nvidia/setup/gpu_monitoring.sh
#!/bin/bash

# Install NVIDIA Data Center GPU Manager (DCGM)
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/datacenter-gpu-manager_3.1.7_amd64.deb
sudo dpkg -i datacenter-gpu-manager_3.1.7_amd64.deb
sudo systemctl start nvidia-dcgm
sudo systemctl enable nvidia-dcgm

# Install DCGM Exporter for Prometheus
docker pull nvidia/dcgm-exporter:latest
docker run -d --restart=always --gpus all -p 9400:9400 nvidia/dcgm-exporter:latest

# Test DCGM metrics
curl localhost:9400/metrics