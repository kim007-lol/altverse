-- Reading progress (upserted on every page turn)
CREATE TABLE trc_reading_histories (
    user_id             BIGINT NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    episode_id          BIGINT NOT NULL REFERENCES cnt_episodes(id) ON DELETE CASCADE,
    last_read_page      INT    NOT NULL DEFAULT 1,
    progress_percentage NUMERIC(5, 2) NOT NULL DEFAULT 0,
    last_read_at        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, episode_id)
);

CREATE INDEX idx_trc_reading_histories_episode_id  ON trc_reading_histories (episode_id);
CREATE INDEX idx_trc_reading_histories_last_read   ON trc_reading_histories (user_id, last_read_at DESC);

-- Analytic view log (high-write, anonymous-friendly)
CREATE TABLE trc_views_log (
    id         BIGSERIAL    PRIMARY KEY,
    episode_id BIGINT       NOT NULL REFERENCES cnt_episodes(id) ON DELETE CASCADE,
    user_id    BIGINT       REFERENCES usr_users(id) ON DELETE SET NULL,
    ip_address VARCHAR(45),
    viewed_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trc_views_log_episode_id ON trc_views_log (episode_id);
CREATE INDEX idx_trc_views_log_viewed_at  ON trc_views_log (viewed_at);
