-- infrastructure/database/migrations/versions/001_initial_schema.sql

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Create schemas
CREATE SCHEMA IF NOT EXISTS layla_app;
CREATE SCHEMA IF NOT EXISTS layla_ml;

-- Set search path
SET search_path TO layla_app, public;

-- Audit timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Base table for common fields
CREATE TABLE base_table (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT true
);

-- Create indexes on base table
CREATE INDEX idx_base_created_at ON base_table(created_at);
CREATE INDEX idx_base_updated_at ON base_table(updated_at);

-- Common trigger for updated_at
CREATE TRIGGER update_base_updated_at
    BEFORE UPDATE ON base_table
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();