# infrastructure/nvidia/config/gpu_config.py

from dataclasses import dataclass
from typing import List, Optional, Dict

@dataclass
class GPUConfig:
    """GPU Configuration for ML workloads"""
    
    device_id: int
    memory_fraction: float = 0.9
    allow_growth: bool = True
    xla_enabled: bool = True
    mixed_precision: bool = True
    
    def to_dict(self) -> Dict:
        return {
            "device_id": self.device_id,
            "memory_fraction": self.memory_fraction,
            "allow_growth": self.allow_growth,
            "xla_enabled": self.xla_enabled,
            "mixed_precision": self.mixed_precision
        }

class GPUManager:
    """GPU Resource Manager"""
    
    def __init__(self):
        import torch
        import tensorflow as tf
        self.torch = torch
        self.tf = tf
        
        # Configure TensorFlow
        self._configure_tensorflow()
        
        # Configure PyTorch
        self._configure_pytorch()
    
    def _configure_tensorflow(self):
        """Configure TensorFlow GPU settings"""
        gpus = self.tf.config.list_physical_devices('GPU')
        if gpus:
            try:
                for gpu in gpus:
                    self.tf.config.experimental.set_memory_growth(gpu, True)
                self.tf.config.experimental.set_visible_devices(gpus[0], 'GPU')
            except RuntimeError as e:
                print(f"TensorFlow GPU configuration error: {e}")
    
    def _configure_pytorch(self):
        """Configure PyTorch GPU settings"""
        if self.torch.cuda.is_available():
            # Set default device
            self.torch.cuda.set_device(0)
            
            # Enable TensorRT optimization if available
            if hasattr(self.torch, 'backends') and hasattr(self.torch.backends, 'cudnn'):
                self.torch.backends.cudnn.benchmark = True
                self.torch.backends.cudnn.enabled = True
    
    def get_gpu_info(self) -> Dict:
        """Get GPU information"""
        if self.torch.cuda.is_available():
            return {
                "device_count": self.torch.cuda.device_count(),
                "current_device": self.torch.cuda.current_device(),
                "device_name": self.torch.cuda.get_device_name(),
                "memory_allocated": self.torch.cuda.memory_allocated(),
                "memory_cached": self.torch.cuda.memory_cached()
            }
        return {"status": "GPU not available"}
    
    def optimize_model_for_inference(self, model, input_shape: tuple):
        """Optimize model for inference using TensorRT"""
        if not self.torch.cuda.is_available():
            return model
        
        try:
            import tensorrt as trt
            from torch2trt import torch2trt
            
            # Create example input
            x = self.torch.randn(input_shape).cuda()
            
            # Convert to TensorRT
            model_trt = torch2trt(
                model.cuda().eval(),
                [x],
                fp16_mode=True,
                max_batch_size=32
            )
            
            return model_trt
        except Exception as e:
            print(f"TensorRT optimization failed: {e}")
            return model

# Example usage:
if __name__ == "__main__":
    # Initialize GPU Manager
    gpu_manager = GPUManager()
    
    # Get GPU information
    gpu_info = gpu_manager.get_gpu_info()
    print("GPU Information:", gpu_info)
    
    # Configure GPU for specific model
    config = GPUConfig(
        device_id=0,
        memory_fraction=0.8,
        allow_growth=True,
        xla_enabled=True,
        mixed_precision=True
    )
    print("GPU Configuration:", config.to_dict())