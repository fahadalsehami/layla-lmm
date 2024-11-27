# backend/utils/preprocessing.py

import numpy as np
import torch
from typing import Tuple, List, Dict, Any
from sklearn.preprocessing import StandardScaler
import cv2

class BiomarkerPreprocessor:
    """Biomarker Data Preprocessing"""
    
    def __init__(self):
        self.face_scaler = StandardScaler()
        self.voice_scaler = StandardScaler()
    
    def preprocess_facial(
        self,
        frame: np.ndarray,
        target_size: Tuple[int, int] = (224, 224)
    ) -> torch.Tensor:
        """Preprocess facial frame"""
        # Resize
        frame = cv2.resize(frame, target_size)
        
        # Normalize
        frame = frame / 255.0
        
        # Convert to tensor
        tensor = torch.from_numpy(frame).float()
        
        # Add batch dimension
        if len(tensor.shape) == 3:
            tensor = tensor.unsqueeze(0)
        
        # Move channels to correct dimension
        tensor = tensor.permute(0, 3, 1, 2)
        
        return tensor
    
    def preprocess_vocal(
        self,
        audio: np.ndarray,
        sample_rate: int = 16000
    ) -> torch.Tensor:
        """Preprocess vocal data"""
        # Normalize audio
        audio = audio / np.max(np.abs(audio))
        
        # Convert to tensor
        tensor = torch.from_numpy(audio).float()
        
        # Add batch and channel dimensions
        if len(tensor.shape) == 1:
            tensor = tensor.unsqueeze(0).unsqueeze(0)
        
        return tensor