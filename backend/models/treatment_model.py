# backend/models/treatment_model.py

from sqlalchemy import Column, Integer, String, JSON, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
from typing import Dict, Any, List

Base = declarative_base()

class Treatment(Base):
    """Treatment Database Model"""
    
    __tablename__ = "treatments"
    
    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(String, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Treatment Details
    treatment_plan = Column(JSON)
    recommendations = Column(JSON)
    interventions = Column(JSON)
    
    # RDoC Integration
    rdoc_targets = Column(JSON)
    rdoc_outcomes = Column(JSON)
    
    # RAG System Integration
    rag_analysis = Column(JSON)
    llm_recommendations = Column(JSON)
    
    # Relationships
    assessments = relationship("Assessment", back_populates="treatment")
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "patient_id": self.patient_id,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "treatment_plan": self.treatment_plan,
            "recommendations": self.recommendations,
            "interventions": self.interventions,
            "rdoc_targets": self.rdoc_targets,
            "rdoc_outcomes": self.rdoc_outcomes,
            "rag_analysis": self.rag_analysis,
            "llm_recommendations": self.llm_recommendations
        }

class TreatmentIntervention(Base):
    """Treatment Intervention Model"""
    
    __tablename__ = "treatment_interventions"
    
    id = Column(Integer, primary_key=True, index=True)
    treatment_id = Column(Integer, ForeignKey('treatments.id'))
    
    # Intervention Details
    type = Column(String)
    description = Column(String)
    frequency = Column(String)
    duration = Column(String)
    status = Column(String)
    
    # Monitoring
    progress_notes = Column(JSON)
    outcomes = Column(JSON)
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "treatment_id": self.treatment_id,
            "type": self.type,
            "description": self.description,
            "frequency": self.frequency,
            "duration": self.duration,
            "status": self.status,
            "progress_notes": self.progress_notes,
            "outcomes": self.outcomes
        }