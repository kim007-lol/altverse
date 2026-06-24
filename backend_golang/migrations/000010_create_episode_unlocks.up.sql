-- Records which reader has paid coins to unlock which premium episode.
-- One row per (user, episode); the unique constraint prevents double-purchase.
CREATE TABLE trx_episode_unlocks (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES usr_users(id)   ON DELETE CASCADE,
    episode_id  BIGINT NOT NULL REFERENCES cnt_episodes(id) ON DELETE CASCADE,
    coins_spent INT    NOT NULL DEFAULT 0,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, episode_id)
);

CREATE INDEX idx_trx_episode_unlocks_user_id    ON trx_episode_unlocks (user_id);
CREATE INDEX idx_trx_episode_unlocks_episode_id ON trx_episode_unlocks (episode_id);
