-- infrastructure/database/migrations/versions/003_biomarker_tables.sql

SET search_path TO layla_app, public;

-- Biomarker types enum
CREATE TYPE biomarker_type AS ENUM ('facial', 'vocal', 'physiological');

-- Biomarker records table
CREATE TABLE biomarker_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL,
    biomarker_type biomarker_type NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    raw_data JSONB NOT NULL,
    processed_data JSONB,
    metadata JSONB,
    quality_score FLOAT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Facial biomarkers table
CREATE TABLE facial_biomarkers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    record_id UUID NOT NULL REFERENCES biomarker_records(id),
    action_units JSONB NOT NULL,
    landmarks JSONB NOT NULL,
    emotions JSONB,
    head_pose JSONB,
    gaze_direction JSONB,
    quality_metrics JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Vocal biomarkers table
CREATE TABLE vocal_biomarkers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    record_id UUID NOT NULL REFERENCES biomarker_records(id),
    acoustic_features JSONB NOT NULL,
    prosodic_features JSONB NOT NULL,
    spectral_features JSONB,
    voice_quality JSONB,
    temporal_features JSONB,
    quality_metrics JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_biomarker_records_session ON biomarker_records(session_id);
CREATE INDEX idx_biomarker_records_type ON biomarker_records(biomarker_type);
CREATE INDEX idx_biomarker_records_timestamp ON biomarker_records(timestamp);
CREATE INDEX idx_facial_biomarkers_record ON facial_biomarkers(record_id);
CREATE INDEX idx_vocal_biomarkers_record ON vocal_biomarkers(record_id);