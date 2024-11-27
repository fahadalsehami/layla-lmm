# backend/utils/validation.py

from typing import Dict, Any, Optional
from pydantic import BaseModel, validator
from datetime import datetime

class BiomarkerData(BaseModel):
    """Biomarker Data Validation Schema"""
    
    session_id: str
    timestamp: datetime
    facial_data: Optional[Dict[str, Any]]
    vocal_data: Optional[Dict[str, Any]]
    
    @validator('facial_data')
    def validate_facial_data(cls, v):
        if v is not None:
            required_keys = {'features', 'action_units', 'emotions'}
            if not all(key in v for key in required_keys):
                raise ValueError(
                    f"facial_data must contain all required keys: {required_keys}"
                )
        return v
    
    @validator('vocal_data')
    def validate_vocal_data(cls, v):
        if v is not None:
            required_keys = {'features', 'prosody', 'quality'}
            if not all(key in v for key in required_keys):
                raise ValueError(
                    f"vocal_data must contain all required keys: {required_keys}"
                )
        return v