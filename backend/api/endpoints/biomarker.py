# backend/api/endpoints/biomarker.py

from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from sqlalchemy.orm import Session
from typing import Dict, Any, List
import numpy as np

from backend.core.database import get_db
from backend.models.biomarker_model import BiomarkerRecord
from backend.utils.preprocessing import BiomarkerPreprocessor
from backend.services.aws_service import AWSService
from backend.services.nvidia_service import NvidiaService
from backend.core.logging import logger

router = APIRouter()
preprocessor = BiomarkerPreprocessor()
aws_service = AWSService()
nvidia_service = NvidiaService()

@router.post("/process/", response_model=Dict[str, Any])
async def process_biomarkers(
    session_id: str,
    facial_data: UploadFile = File(...),
    vocal_data: UploadFile = File(...),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Process facial and vocal biomarkers"""
    try:
        # Read and preprocess data
        facial_array = np.frombuffer(await facial_data.read(), dtype=np.uint8)
        vocal_array = np.frombuffer(await vocal_data.read(), dtype=np.float32)
        
        # Preprocess biomarkers
        facial_tensor = preprocessor.preprocess_facial(facial_array)
        vocal_tensor = preprocessor.preprocess_vocal(vocal_array)
        
        # Move to GPU if available
        facial_tensor = nvidia_service.to_device(facial_tensor)
        vocal_tensor = nvidia_service.to_device(vocal_tensor)
        
        # Extract features
        facial_features = nvidia_service.extract_facial_features(facial_tensor)
        vocal_features = nvidia_service.extract_vocal_features(vocal_tensor)
        
        # Process emotions and metrics
        emotions = nvidia_service.process_emotions(facial_features)
        action_units = nvidia_service.process_action_units(facial_features)
        prosody = nvidia_service.process_prosody(vocal_features)
        
        # Create record
        record = BiomarkerRecord(
            session_id=session_id,
            facial_features=facial_features.cpu().numpy().tolist(),
            facial_action_units=action_units,
            facial_emotions=emotions,
            vocal_features=vocal_features.cpu().numpy().tolist(),
            vocal_prosody=prosody,
            arousal_level=float(np.mean(emotions["arousal"])),
            valence_level=float(np.mean(emotions["valence"])),
            stress_level=float(np.mean(emotions["stress"]))
        )
        
        db.add(record)
        db.commit()
        
        # Store raw data in S3
        await aws_service.upload_biomarker_data(
            session_id,
            facial_data=facial_array,
            vocal_data=vocal_array
        )
        
        return {
            "record_id": record.id,
            "emotions": emotions,
            "action_units": action_units,
            "prosody": prosody,
            "metrics": {
                "arousal": record.arousal_level,
                "valence": record.valence_level,
                "stress": record.stress_level
            }
        }
        
    except Exception as e:
        logger.error(f"Error processing biomarkers: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/metrics/{session_id}", response_model=Dict[str, Any])
async def get_biomarker_metrics(
    session_id: str,
    start_time: Optional[datetime] = None,
    end_time: Optional[datetime] = None,
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Get biomarker metrics for a session"""
    try:
        query = db.query(BiomarkerRecord).filter(
            BiomarkerRecord.session_id == session_id
        )
        
        if start_time:
            query = query.filter(BiomarkerRecord.timestamp >= start_time)
        if end_time:
            query = query.filter(BiomarkerRecord.timestamp <= end_time)
            
        records = query.order_by(BiomarkerRecord.timestamp).all()
        
        return {
            "session_id": session_id,
            "metrics": {
                "arousal": [r.arousal_level for r in records],
                "valence": [r.valence_level for r in records],
                "stress": [r.stress_level for r in records]
            },
            "timestamps": [r.timestamp.isoformat() for r in records]
        }
        
    except Exception as e:
        logger.error(f"Error retrieving biomarker metrics: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )