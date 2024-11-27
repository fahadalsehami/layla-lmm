# Continuing backend/api/endpoints/treatment.py

async def _get_recent_biomarkers(
    session_id: str,
    db: Session,
    timeframe: int = 7  # days
) -> Dict[str, Any]:
    """Get recent biomarker data for treatment planning
    
    Args:
        session_id: Session identifier
        db: Database session
        timeframe: Number of days of data to retrieve
        
    Returns:
        Dict containing processed biomarker data
    """
    try:
        # Calculate time threshold
        threshold = datetime.utcnow() - timedelta(days=timeframe)
        
        # Query biomarker records
        records = db.query(BiomarkerRecord).filter(
            BiomarkerRecord.session_id == session_id,
            BiomarkerRecord.timestamp >= threshold
        ).order_by(BiomarkerRecord.timestamp).all()
        
        if not records:
            return {
                "status": "no_data",
                "message": "No recent biomarker data available"
            }
        
        # Process and aggregate biomarker data
        processed_data = {
            "emotional_metrics": {
                "arousal": {
                    "mean": float(np.mean([r.arousal_level for r in records])),
                    "std": float(np.std([r.arousal_level for r in records])),
                    "trend": _calculate_trend([r.arousal_level for r in records])
                },
                "valence": {
                    "mean": float(np.mean([r.valence_level for r in records])),
                    "std": float(np.std([r.valence_level for r in records])),
                    "trend": _calculate_trend([r.valence_level for r in records])
                },
                "stress": {
                    "mean": float(np.mean([r.stress_level for r in records])),
                    "std": float(np.std([r.stress_level for r in records])),
                    "trend": _calculate_trend([r.stress_level for r in records])
                }
            },
            "facial_analysis": _aggregate_facial_data(records),
            "vocal_analysis": _aggregate_vocal_data(records),
            "temporal_patterns": _analyze_temporal_patterns(records),
            "metadata": {
                "record_count": len(records),
                "start_time": records[0].timestamp.isoformat(),
                "end_time": records[-1].timestamp.isoformat()
            }
        }
        
        return processed_data
        
    except Exception as e:
        logger.error(f"Error retrieving biomarker data: {str(e)}")
        return {
            "status": "error",
            "message": "Error processing biomarker data"
        }

async def _generate_next_steps(
    treatment: Treatment,
    interventions: List[TreatmentIntervention]
) -> List[Dict[str, Any]]:
    """Generate recommended next steps based on current progress
    
    Args:
        treatment: Treatment record
        interventions: List of interventions
        
    Returns:
        List of recommended next steps
    """
    try:
        # Analyze current status
        status_analysis = _analyze_treatment_status(treatment, interventions)
        
        # Generate RAG-based recommendations
        rag_recommendations = await rag_system.generate_recommendations({
            "treatment_plan": treatment.treatment_plan,
            "current_status": status_analysis,
            "rdoc_targets": treatment.rdoc_targets,
            "rdoc_outcomes": treatment.rdoc_outcomes
        })
        
        # Process and prioritize recommendations
        next_steps = []
        
        # Handle critical interventions
        for intervention in interventions:
            if intervention.status == "in_progress" and intervention.outcomes["progress"] < 50:
                next_steps.append({
                    "priority": "high",
                    "type": "intervention_adjustment",
                    "intervention_id": intervention.id,
                    "recommendation": (
                        f"Review and adjust {intervention.type} intervention - "
                        f"Current progress: {intervention.outcomes['progress']}%"
                    ),
                    "suggested_actions": _generate_intervention_actions(intervention)
                })
        
        # Add RAG recommendations
        for rec in rag_recommendations:
            next_steps.append({
                "priority": rec["priority"],
                "type": "rag_recommendation",
                "recommendation": rec["description"],
                "rationale": rec["rationale"],
                "suggested_actions": rec["actions"]
            })
        
        # Sort by priority
        priority_order = {"high": 0, "medium": 1, "low": 2}
        next_steps.sort(key=lambda x: priority_order[x["priority"]])
        
        return next_steps
        
    except Exception as e:
        logger.error(f"Error generating next steps: {str(e)}")
        return [{
            "priority": "high",
            "type": "error",
            "recommendation": "Error generating recommendations"
        }]

def _calculate_trend(
    values: List[float],
    window: int = 3
) -> str:
    """Calculate trend direction from series of values"""
    if len(values) < window:
        return "insufficient_data"
        
    # Calculate moving average
    ma = np.convolve(values, np.ones(window)/window, mode='valid')
    
    if len(ma) < 2:
        return "stable"
        
    # Calculate trend
    trend = ma[-1] - ma[0]
    
    if abs(trend) < 0.1:  # Threshold for stability
        return "stable"
    return "increasing" if trend > 0 else "decreasing"

def _aggregate_facial_data(records: List[BiomarkerRecord]) -> Dict[str, Any]:
    """Aggregate facial biomarker data"""
    facial_data = {
        "dominant_emotions": {},
        "action_unit_frequencies": {},
        "emotion_transitions": {}
    }
    
    for record in records:
        # Process emotions
        if record.facial_emotions:
            for emotion, value in record.facial_emotions.items():
                if emotion not in facial_data["dominant_emotions"]:
                    facial_data["dominant_emotions"][emotion] = []
                facial_data["dominant_emotions"][emotion].append(value)
        
        # Process action units
        if record.facial_action_units:
            for au, value in record.facial_action_units.items():
                if au not in facial_data["action_unit_frequencies"]:
                    facial_data["action_unit_frequencies"][au] = []
                facial_data["action_unit_frequencies"][au].append(value)
    
    # Calculate averages and frequencies
    for emotion in facial_data["dominant_emotions"]:
        facial_data["dominant_emotions"][emotion] = np.mean(
            facial_data["dominant_emotions"][emotion]
        )
    
    for au in facial_data["action_unit_frequencies"]:
        facial_data["action_unit_frequencies"][au] = np.mean(
            facial_data["action_unit_frequencies"][au]
        )
    
    return facial_data

def _aggregate_vocal_data(records: List[BiomarkerRecord]) -> Dict[str, Any]:
    """Aggregate vocal biomarker data"""
    vocal_data = {
        "prosody_metrics": {},
        "quality_metrics": {},
        "speech_patterns": {}
    }
    
    for record in records:
        if record.vocal_prosody:
            for metric, value in record.vocal_prosody.items():
                if metric not in vocal_data["prosody_metrics"]:
                    vocal_data["prosody_metrics"][metric] = []
                vocal_data["prosody_metrics"][metric].append(value)
        
        if record.vocal_quality:
            for metric, value in record.vocal_quality.items():
                if metric not in vocal_data["quality_metrics"]:
                    vocal_data["quality_metrics"][metric] = []
                vocal_data["quality_metrics"][metric].append(value)
    
    # Calculate averages
    for category in ["prosody_metrics", "quality_metrics"]:
        for metric in vocal_data[category]:
            vocal_data[category][metric] = {
                "mean": float(np.mean(vocal_data[category][metric])),
                "std": float(np.std(vocal_data[category][metric])),
                "trend": _calculate_trend(vocal_data[category][metric])
            }
    
    return vocal_data

def _analyze_temporal_patterns(
    records: List[BiomarkerRecord]
) -> Dict[str, Any]:
    """Analyze temporal patterns in biomarker data"""
    timestamps = [r.timestamp for r in records]
    time_diffs = np.diff([t.timestamp() for t in timestamps])
    
    return {
        "session_frequency": {
            "mean_interval": float(np.mean(time_diffs)) if len(time_diffs) > 0 else 0,
            "std_interval": float(np.std(time_diffs)) if len(time_diffs) > 0 else 0
        },
        "time_of_day_distribution": _analyze_time_distribution(timestamps),
        "weekly_pattern": _analyze_weekly_pattern(timestamps)
    }

def _analyze_treatment_status(
    treatment: Treatment,
    interventions: List[TreatmentIntervention]
) -> Dict[str, Any]:
    """Analyze current treatment status"""
    return {
        "overall_status": {
            "active_interventions": len([
                i for i in interventions if i.status == "in_progress"
            ]),
            "completed_interventions": len([
                i for i in interventions if i.status == "completed"
            ]),
            "duration": (datetime.utcnow() - treatment.created_at).days
        },
        "intervention_status": {
            i.type: {
                "status": i.status,
                "progress": i.outcomes["progress"],
                "duration": (
                    datetime.utcnow() - 
                    datetime.fromisoformat(i.progress_notes[0]["timestamp"])
                    if i.progress_notes else timedelta(0)
                ).days
            }
            for i in interventions
        },
        "rdoc_alignment": _analyze_rdoc_alignment(
            treatment.rdoc_targets,
            treatment.rdoc_outcomes
        )
    }

def _generate_intervention_actions(
    intervention: TreatmentIntervention
) -> List[Dict[str, Any]]:
    """Generate suggested actions for intervention adjustment"""
    actions = []
    
    # Check progress and generate appropriate actions
    if intervention.outcomes["progress"] < 25:
        actions.append({
            "type": "review",
            "description": "Comprehensive intervention review needed",
            "priority": "high"
        })
    elif intervention.outcomes["progress"] < 50:
        actions.append({
            "type": "adjust",
            "description": "Consider adjusting intervention parameters",
            "priority": "medium"
        })
    
    # Check duration against planned duration
    if intervention.duration:
        planned_duration = parse_duration(intervention.duration)
        current_duration = len(intervention.progress_notes)
        
        if current_duration > planned_duration:
            actions.append({
                "type": "duration_review",
                "description": "Intervention exceeding planned duration",
                "priority": "medium"
            })
    
    return actions

def _analyze_rdoc_alignment(
    targets: Dict[str, Any],
    outcomes: Dict[str, Any]
) -> Dict[str, Any]:
    """Analyze alignment between RDoC targets and outcomes"""
    alignment = {}
    
    for domain in targets:
        if domain in outcomes:
            alignment[domain] = {
                "status": _calculate_alignment_status(
                    targets[domain],
                    outcomes[domain]
                ),
                "gap_analysis": _calculate_domain_gaps(
                    targets[domain],
                    outcomes[domain]
                )
            }
    
    return alignment

# Add the endpoint to get aggregated biomarker analysis
@router.get("/biomarker-analysis/{session_id}", response_model=Dict[str, Any])
async def get_biomarker_analysis(
    session_id: str,
    timeframe: int = Query(7, gt=0, le=30),
    db: Session = Depends(get_db)
) -> Dict[str, Any]:
    """Get aggregated biomarker analysis for treatment planning"""
    try:
        biomarker_data = await _get_recent_biomarkers(
            session_id,
            db,
            timeframe
        )
        
        if biomarker_data["status"] == "error":
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=biomarker_data["message"]
            )
        
        return biomarker_data
        
    except Exception as e:
        logger.error(f"Error retrieving biomarker analysis: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
#    
# 1. Add more utility functions
# 2. Implement additional endpoints
# 3. Add more detailed documentation
# 4. Explain any specific part in detail?