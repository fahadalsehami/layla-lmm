# backend/services/nvidia_service.py

import torch
import logging
from backend.core.config import settings

logger = logging.getLogger(__name__)

class NvidiaService:
    """Nvidia GPU Service Integration"""
    
    def __init__(self):
        self.device = torch.device(
            "cuda" if torch.cuda.is_available() else "cpu"
        )
        if torch.cuda.is_available():
            torch.cuda.set_device(int(settings.nvidia.CUDA_VISIBLE_DEVICES))
    
    def setup_tensorrt(self, model):
        """Setup TensorRT for model optimization"""
        if settings.nvidia.TENSORRT_MODE and torch.cuda.is_available():
            try:
                import torch2trt
                model_trt = torch2trt.torch2trt(
                    model,
                    [torch.randn(1, 3, 224, 224).to(self.device)],
                    fp16_mode=True
                )
                logger.info("Successfully converted model to TensorRT")
                return model_trt
            except Exception as e:
                logger.error(f"Error setting up TensorRT: {e}")
                return model
        return model
    
    def get_gpu_info(self):
        """Get GPU information"""
        if torch.cuda.is_available():
            return {
                "device_name": torch.cuda.get_device_name(),
                "device_count": torch.cuda.device_count(),
                "current_device": torch.cuda.current_device(),
                "memory_allocated": torch.cuda.memory_allocated(),
                "memory_cached": torch.cuda.memory_cached()
            }
        return {"status": "GPU not available"}