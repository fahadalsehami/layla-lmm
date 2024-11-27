# backend/models/assessment_model.py

from sqlalchemy import Column, Integer, String, Float, JSON, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime
from typing import Dict, Any, List
import enum

Base = declarative_base()

class AssessmentType(enum.Enum):
    """Types of Assessments"""
    PHQ9 = "PHQ-9"
    GAD7 = "GAD-7"
    RDOC = "RDoC"
    CUSTOM = "CUSTOM"

class Assessment(Base):
    """Assessment Database Model"""
    
    __tablename__ = "assessments"
    
    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String, index=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
    assessment_type = Column(String)
    
    # Scores and Responses
    scores = Column(JSON)  # Raw scores for each question
    total_score = Column(Float)
    severity_level = Column(String)
    
    # RDoC Matrix Integration
    rdoc_domains = Column(JSON)
    rdoc_constructs = Column(JSON)
    
    # LLM Analysis
    llm_analysis = Column(JSON)
    
    # Relationships
    treatment_id = Column(Integer, ForeignKey('treatments.id'))
    treatment = relationship("Treatment", back_populates="assessments")
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "session_id": self.session_id,
            "timestamp": self.timestamp.isoformat(),
            "assessment_type": self.assessment_type,
            "scores": self.scores,
            "total_score": self.total_score,
            "severity_level": self.severity_level,
            "rdoc_domains": self.rdoc_domains,
            "rdoc_constructs": self.rdoc_constructs,
            "llm_analysis": self.llm_analysis
        }

class PHQ9Assessment(Base):
    """PHQ-9 Specific Assessment Model"""
    
    __tablename__ = "phq9_assessments"
    
    id = Column(Integer, primary_key=True, index=True)
    assessment_id = Column(Integer, ForeignKey('assessments.id'))
    
    # PHQ-9 Specific Fields
    question_responses = Column(JSON)
    suicidal_ideation_score = Column(Integer)
    functional_impact = Column(String)
    
    # Classification
    depression_severity = Column(String)
    risk_level = Column(String)
    
    @staticmethod
    def calculate_severity(total_score: int) -> str:
        if total_score <= 4:
            return "Minimal"
        elif total_score <= 9:
            return "Mild"
        elif total_score <= 14:
            return "Moderate"
        elif total_score <= 19:
            return "Moderately Severe"
        else:
            return "Severe"

class GAD7Assessment(Base):
    """GAD-7 Specific Assessment Model"""
    
    __tablename__ = "gad7_assessments"
    
    id = Column(Integer, primary_key=True, index=True)
    assessment_id = Column(Integer, ForeignKey('assessments.id'))
    
    # GAD-7 Specific Fields
    question_responses = Column(JSON)
    functional_impact = Column(String)
    
    # Classification
    anxiety_severity = Column(String)
    
    @staticmethod
    def calculate_severity(total_score: int) -> str:
        if total_score <= 4:
            return "Minimal"
        elif total_score <= 9:
            return "Mild"
        elif total_score <= 14:
            return "Moderate"
        else:
            return "Severe"