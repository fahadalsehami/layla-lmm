# backend/api/endpoints/assessment.py

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Dict, Any, List, Optional
from datetime import datetime
import numpy as np

from backend.core.database import get_db
from backend.models.assessment_model import (
    Assessment,
    PHQ9Assessment,
    GAD7Assessment,
    AssessmentType
)
from backend.services.rag_service import RAGSystem
from backend.core.logging import logger

router = APIRouter()
rag_system = RAGSystem()

@router.post("/phq9/", response_model=Dict[str, Any])
async def create_phq9_assessment(
    assessment_data: Dict[str, Any],
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Create PHQ-9 assessment"""
    try:
        # Validate responses
        if len(assessment_data["responses"]) != 9:
            raise ValueError("PHQ-9 requires exactly 9 responses")
            
        # Calculate scores
        total_score = sum(assessment_data["responses"].values())
        severity = PHQ9Assessment.calculate_severity(total_score)
        
        # Create base assessment
        assessment = Assessment(
            session_id=assessment_data["session_id"],
            assessment_type=AssessmentType.PHQ9.value,
            scores=assessment_data["responses"],
            total_score=total_score,
            severity_level=severity
        )
        db.add(assessment)
        db.flush()
        
        # Create PHQ-9 specific assessment
        phq9 = PHQ9Assessment(
            assessment_id=assessment.id,
            question_responses=assessment_data["responses"],
            suicidal_ideation_score=assessment_data["responses"].get(9, 0),
            functional_impact=assessment_data.get("functional_impact", ""),
            depression_severity=severity,
            risk_level=_calculate_risk_level(assessment_data["responses"])
        )
        db.add(phq9)
        
        # Generate RAG analysis
        rag_analysis = await rag_system.analyze_assessment({
            "type": "PHQ-9",
            "responses": assessment_data["responses"],
            "total_score": total_score,
            "severity": severity
        })
        
        assessment.llm_analysis = rag_analysis
        assessment.rdoc_domains = rag_analysis.get("rdoc_domains", {})
        assessment.rdoc_constructs = rag_analysis.get("rdoc_constructs", {})
        
        db.commit()
        
        return {
            "assessment_id": assessment.id,
            "severity": severity,
            "risk_level": phq9.risk_level,
            "analysis": rag_analysis,
            "recommendations": rag_analysis.get("recommendations", [])
        }
        
    except Exception as e:
        logger.error(f"Error creating PHQ-9 assessment: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/gad7/", response_model=Dict[str, Any])
async def create_gad7_assessment(
    assessment_data: Dict[str, Any],
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Create GAD-7 assessment"""
    try:
        # Validate responses
        if len(assessment_data["responses"]) != 7:
            raise ValueError("GAD-7 requires exactly 7 responses")
            
        # Calculate scores
        total_score = sum(assessment_data["responses"].values())
        severity = GAD7Assessment.calculate_severity(total_score)
        
        # Create base assessment
        assessment = Assessment(
            session_id=assessment_data["session_id"],
            assessment_type=AssessmentType.GAD7.value,
            scores=assessment_data["responses"],
            total_score=total_score,
            severity_level=severity
        )
        db.add(assessment)
        db.flush()
        
        # Create GAD-7 specific assessment
        gad7 = GAD7Assessment(
            assessment_id=assessment.id,
            question_responses=assessment_data["responses"],
            functional_impact=assessment_data.get("functional_impact", ""),
            anxiety_severity=severity
        )
        db.add(gad7)
        
        # Generate RAG analysis
        rag_analysis = await rag_system.analyze_assessment({
            "type": "GAD-7",
            "responses": assessment_data["responses"],
            "total_score": total_score,
            "severity": severity
        })
        
        assessment.llm_analysis = rag_analysis
        assessment.rdoc_domains = rag_analysis.get("rdoc_domains", {})
        assessment.rdoc_constructs = rag_analysis.get("rdoc_constructs", {})
        
        db.commit()
        
        return {
            "assessment_id": assessment.id,
            "severity": severity,
            "analysis": rag_analysis,
            "recommendations": rag_analysis.get("recommendations", [])
        }
        
    except Exception as e:
        logger.error(f"Error creating GAD-7 assessment: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/history/{session_id}", response_model=List[Dict[str, Any]])
async def get_assessment_history(
    session_id: str,
    assessment_type: Optional[str] = None,
    db: Session = Depends(get_db)
) -> List[Dict[str, Any]]:
    """Get assessment history for a session"""
    try:
        query = db.query(Assessment).filter(
            Assessment.session_id == session_id
        )
        
        if assessment_type:
            query = query.filter(Assessment.assessment_type == assessment_type)
            
        assessments = query.order_by(Assessment.timestamp.desc()).all()
        
        return [assessment.to_dict() for assessment in assessments]
        
    except Exception as e:
        logger.error(f"Error retrieving assessment history: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )