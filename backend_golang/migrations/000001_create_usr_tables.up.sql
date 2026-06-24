CREATE TYPE usr_role AS ENUM ('reader', 'author', 'admin');

CREATE TABLE usr_users (
    id               BIGSERIAL PRIMARY KEY,
    name             VARCHAR(255)  NOT NULL,
    email            VARCHAR(255)  NOT NULL UNIQUE,
    password         VARCHAR(255)  NOT NULL,
    role             usr_role      NOT NULL DEFAULT 'reader',
    avatar_url       VARCHAR(512),
    pen_name         VARCHAR(255),
    bio              TEXT,
    social_links     JSONB,
    level            INT           NOT NULL DEFAULT 1,
    exp_points       INT           NOT NULL DEFAULT 0,
    coins            INT           NOT NULL DEFAULT 0,
    author_tier      VARCHAR(50)   NOT NULL DEFAULT 'bronze',
    theme_preference VARCHAR(20)   NOT NULL DEFAULT 'dark',
    created_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at       TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_usr_users_email      ON usr_users (email);
CREATE INDEX idx_usr_users_role       ON usr_users (role);
CREATE INDEX idx_usr_users_deleted_at ON usr_users (deleted_at);

CREATE TABLE usr_refresh_tokens (
    id         BIGSERIAL    PRIMARY KEY,
    user_id    BIGINT       NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    token_id   VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_usr_refresh_tokens_user_id  ON usr_refresh_tokens (user_id);
CREATE INDEX idx_usr_refresh_tokens_token_id ON usr_refresh_tokens (token_id);
