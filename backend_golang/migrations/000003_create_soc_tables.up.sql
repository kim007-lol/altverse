CREATE TYPE soc_report_target AS ENUM ('series', 'episode', 'comment', 'user');
CREATE TYPE soc_report_status AS ENUM ('pending', 'resolved', 'dismissed');

-- Follows (reader -> author)
CREATE TABLE soc_follows (
    follower_id BIGINT NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    followed_id BIGINT NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_id, followed_id),
    CONSTRAINT chk_soc_follows_no_self CHECK (follower_id <> followed_id)
);

CREATE INDEX idx_soc_follows_followed_id ON soc_follows (followed_id);

-- Bookmarks
CREATE TABLE soc_bookmarks (
    user_id    BIGINT NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    series_id  BIGINT NOT NULL REFERENCES cnt_series(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, series_id)
);

CREATE INDEX idx_soc_bookmarks_series_id ON soc_bookmarks (series_id);

-- Series likes
CREATE TABLE soc_series_likes (
    user_id    BIGINT NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    series_id  BIGINT NOT NULL REFERENCES cnt_series(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, series_id)
);

CREATE INDEX idx_soc_series_likes_series_id ON soc_series_likes (series_id);

-- Episode likes
CREATE TABLE soc_episode_likes (
    user_id     BIGINT NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    episode_id  BIGINT NOT NULL REFERENCES cnt_episodes(id) ON DELETE CASCADE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, episode_id)
);

CREATE INDEX idx_soc_episode_likes_episode_id ON soc_episode_likes (episode_id);

-- Comments (supports nested reply via parent_id)
CREATE TABLE soc_comments (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT    NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    episode_id  BIGINT    NOT NULL REFERENCES cnt_episodes(id) ON DELETE CASCADE,
    parent_id   BIGINT    REFERENCES soc_comments(id) ON DELETE CASCADE,
    content     TEXT      NOT NULL,
    is_pinned   BOOLEAN   NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_soc_comments_episode_id  ON soc_comments (episode_id);
CREATE INDEX idx_soc_comments_parent_id   ON soc_comments (parent_id);
CREATE INDEX idx_soc_comments_user_id     ON soc_comments (user_id);
CREATE INDEX idx_soc_comments_deleted_at  ON soc_comments (deleted_at);

-- Comment likes
CREATE TABLE soc_comment_likes (
    user_id     BIGINT NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    comment_id  BIGINT NOT NULL REFERENCES soc_comments(id) ON DELETE CASCADE,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, comment_id)
);

CREATE INDEX idx_soc_comment_likes_comment_id ON soc_comment_likes (comment_id);

-- Reports (polymorphic via target_type + target_id)
CREATE TABLE soc_reports (
    id          BIGSERIAL           PRIMARY KEY,
    reporter_id BIGINT              NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    target_type soc_report_target   NOT NULL,
    target_id   BIGINT              NOT NULL,
    reason      VARCHAR(512)        NOT NULL,
    status      soc_report_status   NOT NULL DEFAULT 'pending',
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_soc_reports_reporter_id          ON soc_reports (reporter_id);
CREATE INDEX idx_soc_reports_target               ON soc_reports (target_type, target_id);
CREATE INDEX idx_soc_reports_status               ON soc_reports (status);
