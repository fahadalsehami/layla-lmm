# infrastructure/nvidia/setup/verify_installation.sh
#!/bin/bash

echo "Verifying NVIDIA Installation..."

# Check NVIDIA driver
nvidia-smi

# Check CUDA installation
nvcc --version

# Check TensorRT installation
python3 -c "import tensorrt; print(tensorrt.__version__)"

# Run simple CUDA test
cat > cuda_test.cu << EOF
#include <stdio.h>

__global__ void cuda_hello(){
    printf("Hello World from GPU!\n");
}

int main() {
    cuda_hello<<<1,1>>>();
    cudaDeviceSynchronize();
    return 0;
}
EOF

nvcc cuda_test.cu -o cuda_test
./cuda_test
