-- infrastructure/database/migrations/versions/004_assessment_tables.sql

SET search_path TO layla_app, public;

-- Assessment types enum
CREATE TYPE assessment_type AS ENUM ('phq9', 'gad7', 'rdoc', 'custom');

-- Assessment status enum
CREATE TYPE assessment_status AS ENUM ('pending', 'in_progress', 'completed', 'invalid');

-- Assessments table
CREATE TABLE assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL,
    assessment_type assessment_type NOT NULL,
    status assessment_status NOT NULL DEFAULT 'pending',
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    scores JSONB,
    total_score FLOAT,
    severity_level VARCHAR(50),
    rdoc_domains JSONB,
    rdoc_constructs JSONB,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Assessment responses table
CREATE TABLE assessment_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_id UUID NOT NULL REFERENCES assessments(id),
    question_id VARCHAR(50) NOT NULL,
    response_value INTEGER NOT NULL,
    response_text TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_assessment_responses UNIQUE (assessment_id, question_id)
);

-- Create indexes
CREATE INDEX idx_assessments_session ON assessments(session_id);
CREATE INDEX idx_assessments_type ON assessments(assessment_type);
CREATE INDEX idx_assessments_status ON assessments(status);
CREATE INDEX idx_assessment_responses_assessment ON assessment_responses(assessment_id);
