# backend/models/biomarker_model.py

from sqlalchemy import Column, Integer, String, Float, JSON, DateTime
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
from typing import Dict, Any

Base = declarative_base()

class BiomarkerRecord(Base):
    """Biomarker Database Model"""
    
    __tablename__ = "biomarker_records"
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String, index=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
    
    # Facial Biomarkers
    facial_features = Column(JSON)
    facial_action_units = Column(JSON)
    facial_emotions = Column(JSON)
    
    # Vocal Biomarkers
    vocal_features = Column(JSON)
    vocal_prosody = Column(JSON)
    vocal_quality = Column(JSON)
    
    # Processed Metrics
    arousal_level = Column(Float)
    valence_level = Column(Float)
    stress_level = Column(Float)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert record to dictionary"""
        return {
            "id": self.id,
            "session_id": self.session_id,
            "timestamp": self.timestamp.isoformat(),
            "facial_features": self.facial_features,
            "facial_action_units": self.facial_action_units,
            "facial_emotions": self.facial_emotions,
            "vocal_features": self.vocal_features,
            "vocal_prosody": self.vocal_prosody,
            "vocal_quality": self.vocal_quality,
            "arousal_level": self.arousal_level,
            "valence_level": self.valence_level,
            "stress_level": self.stress_level
        }