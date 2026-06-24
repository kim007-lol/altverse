-- Notifications inbox
CREATE TABLE ntf_notifications (
    id         BIGSERIAL    PRIMARY KEY,
    user_id    BIGINT       NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    type       VARCHAR(100) NOT NULL,
    title      VARCHAR(512) NOT NULL,
    body       TEXT         NOT NULL,
    data       JSONB,
    is_read    BOOLEAN      NOT NULL DEFAULT FALSE,
    read_at    TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ntf_notifications_user_id ON ntf_notifications (user_id);
CREATE INDEX idx_ntf_notifications_is_read ON ntf_notifications (user_id, is_read);

-- Per-user notification channel preferences
CREATE TABLE ntf_preferences (
    id                BIGSERIAL    PRIMARY KEY,
    user_id           BIGINT       NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    notification_type VARCHAR(100) NOT NULL,
    push_enabled      BOOLEAN      NOT NULL DEFAULT TRUE,
    email_enabled     BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, notification_type)
);

CREATE INDEX idx_ntf_preferences_user_id ON ntf_preferences (user_id);
