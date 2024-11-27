-- infrastructure/database/migrations/versions/005_treatment_tables.sql

SET search_path TO layla_app, public;

-- Treatment status enum
CREATE TYPE treatment_status AS ENUM ('planned', 'in_progress', 'completed', 'cancelled');

-- Intervention type enum
CREATE TYPE intervention_type AS ENUM ('behavioral', 'cognitive', 'medication', 'combined');

-- Treatments table
CREATE TABLE treatments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL,
    status treatment_status NOT NULL DEFAULT 'planned',
    treatment_plan JSONB NOT NULL,
    recommendations JSONB,
    interventions JSONB,
    rdoc_targets JSONB,
    rdoc_outcomes JSONB,
    start_date DATE,
    end_date DATE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Treatment interventions table
CREATE TABLE treatment_interventions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    treatment_id UUID NOT NULL REFERENCES treatments(id),
    intervention_type intervention_type NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    frequency VARCHAR(50),
    duration VARCHAR(50),
    status treatment_status NOT NULL DEFAULT 'planned',
    start_date DATE,
    end_date DATE,
    progress_notes JSONB[],
    outcomes JSONB,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_treatments_patient ON treatments(patient_id);
CREATE INDEX idx_treatments_status ON treatments(status);
CREATE INDEX idx_treatment_interventions_treatment ON treatment_interventions(treatment_id);
CREATE INDEX idx_treatment_interventions_type ON treatment_interventions(intervention_type);