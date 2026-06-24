CREATE TYPE gam_mission_type   AS ENUM ('daily', 'weekly', 'onetime');
CREATE TYPE gam_mission_status AS ENUM ('in_progress', 'completed', 'claimed');

-- Per-user XP & level (1 row per user)
CREATE TABLE gam_user_xp (
    user_id     BIGINT NOT NULL PRIMARY KEY REFERENCES usr_users(id) ON DELETE CASCADE,
    total_xp    INT    NOT NULL DEFAULT 0,
    current_level INT  NOT NULL DEFAULT 1,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Daily XP log — prevents farming (max 1 record per user per source per day)
CREATE TABLE gam_daily_xp_logs (
    id         BIGSERIAL    PRIMARY KEY,
    user_id    BIGINT       NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    source     VARCHAR(100) NOT NULL,
    xp_earned  INT          NOT NULL DEFAULT 0,
    log_date   DATE         NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, source, log_date)
);

CREATE INDEX idx_gam_daily_xp_logs_user_date ON gam_daily_xp_logs (user_id, log_date);

-- Badge definitions
CREATE TABLE gam_badges (
    id              BIGSERIAL    PRIMARY KEY,
    name            VARCHAR(255) NOT NULL UNIQUE,
    slug            VARCHAR(255) NOT NULL UNIQUE,
    description     TEXT,
    icon_url        VARCHAR(512),
    condition_type  VARCHAR(100) NOT NULL,
    condition_value INT          NOT NULL DEFAULT 0,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- User earned badges
CREATE TABLE gam_user_badges (
    user_id    BIGINT NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    badge_id   BIGINT NOT NULL REFERENCES gam_badges(id) ON DELETE CASCADE,
    earned_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, badge_id)
);

CREATE INDEX idx_gam_user_badges_badge_id ON gam_user_badges (badge_id);

-- Mission definitions
CREATE TABLE gam_missions (
    id              BIGSERIAL         PRIMARY KEY,
    title           VARCHAR(512)      NOT NULL,
    description     TEXT,
    type            gam_mission_type  NOT NULL,
    xp_reward       INT               NOT NULL DEFAULT 0,
    coin_reward     INT               NOT NULL DEFAULT 0,
    condition_type  VARCHAR(100)      NOT NULL,
    condition_value INT               NOT NULL DEFAULT 1,
    is_active       BOOLEAN           NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- User mission progress
CREATE TABLE gam_user_missions (
    id           BIGSERIAL          PRIMARY KEY,
    user_id      BIGINT             NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    mission_id   BIGINT             NOT NULL REFERENCES gam_missions(id) ON DELETE CASCADE,
    status       gam_mission_status NOT NULL DEFAULT 'in_progress',
    progress     INT                NOT NULL DEFAULT 0,
    completed_at TIMESTAMP WITH TIME ZONE,
    claimed_at   TIMESTAMP WITH TIME ZONE,
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, mission_id)
);

CREATE INDEX idx_gam_user_missions_user_id    ON gam_user_missions (user_id);
CREATE INDEX idx_gam_user_missions_mission_id ON gam_user_missions (mission_id);

-- Seasons (leaderboard periods)
CREATE TABLE gam_seasons (
    id         BIGSERIAL    PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    start_date DATE         NOT NULL,
    end_date   DATE         NOT NULL,
    is_active  BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- XP leaderboard per season
CREATE TABLE gam_season_xp (
    user_id   BIGINT NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    season_id BIGINT NOT NULL REFERENCES gam_seasons(id) ON DELETE CASCADE,
    xp        INT    NOT NULL DEFAULT 0,
    rank      INT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, season_id)
);

CREATE INDEX idx_gam_season_xp_season_id ON gam_season_xp (season_id);

-- Coins spent supporting authors per season
CREATE TABLE gam_season_supporters (
    user_id     BIGINT NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    author_id   BIGINT NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    season_id   BIGINT NOT NULL REFERENCES gam_seasons(id) ON DELETE CASCADE,
    coins_spent INT    NOT NULL DEFAULT 0,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, author_id, season_id)
);

CREATE INDEX idx_gam_season_supporters_author_season ON gam_season_supporters (author_id, season_id);

-- Author earnings summary per season
CREATE TABLE gam_season_author_earnings (
    author_id     BIGINT         NOT NULL REFERENCES usr_users(id) ON DELETE CASCADE,
    season_id     BIGINT         NOT NULL REFERENCES gam_seasons(id) ON DELETE CASCADE,
    coins_earned  INT            NOT NULL DEFAULT 0,
    rupiah_earned NUMERIC(15, 2) NOT NULL DEFAULT 0,
    created_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (author_id, season_id)
);
