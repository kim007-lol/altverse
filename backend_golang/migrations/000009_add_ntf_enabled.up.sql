-- Master on/off toggle per preference type (separate from push/email channels).
ALTER TABLE ntf_preferences
    ADD COLUMN enabled BOOLEAN NOT NULL DEFAULT TRUE;
