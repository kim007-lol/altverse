CREATE TABLE sys_settings (
    id          BIGSERIAL    PRIMARY KEY,
    key         VARCHAR(255) NOT NULL UNIQUE,
    value       JSONB,
    description TEXT,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);
