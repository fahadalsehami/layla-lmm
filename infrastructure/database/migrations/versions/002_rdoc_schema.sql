-- infrastructure/database/migrations/versions/002_rdoc_schema.sql

SET search_path TO layla_app, public;

-- RDoC Domains table
CREATE TABLE rdoc_domains (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    code VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_rdoc_domains_name UNIQUE (name)
);

-- RDoC Constructs table
CREATE TABLE rdoc_constructs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    domain_id UUID NOT NULL REFERENCES rdoc_domains(id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    code VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_rdoc_constructs_name_domain UNIQUE (name, domain_id)
);

-- RDoC Subconstructs table
CREATE TABLE rdoc_subconstructs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    construct_id UUID NOT NULL REFERENCES rdoc_constructs(id),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    code VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_rdoc_subconstructs_name_construct UNIQUE (name, construct_id)
);

-- Create indexes
CREATE INDEX idx_rdoc_domains_code ON rdoc_domains(code);
CREATE INDEX idx_rdoc_constructs_code ON rdoc_constructs(code);
CREATE INDEX idx_rdoc_subconstructs_code ON rdoc_subconstructs(code);