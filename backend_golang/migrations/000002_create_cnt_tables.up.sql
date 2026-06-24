CREATE TYPE cnt_series_status  AS ENUM ('draft', 'ongoing', 'completed', 'hiatus');
CREATE TYPE cnt_series_type    AS ENUM ('manga', 'manhwa', 'manhua', 'webtoon', 'novel');
CREATE TYPE cnt_episode_status AS ENUM ('draft', 'published', 'scheduled');

CREATE TABLE cnt_genres (
    id         BIGSERIAL    PRIMARY KEY,
    name       VARCHAR(100) NOT NULL UNIQUE,
    slug       VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE cnt_series (
    id           BIGSERIAL          PRIMARY KEY,
    author_id    BIGINT             NOT NULL REFERENCES usr_users(id) ON DELETE RESTRICT,
    title        VARCHAR(512)       NOT NULL,
    slug         VARCHAR(512)       NOT NULL UNIQUE,
    synopsis     TEXT,
    cover_url    VARCHAR(512),
    banner_url   VARCHAR(512),
    type         cnt_series_type    NOT NULL DEFAULT 'manga',
    status       cnt_series_status  NOT NULL DEFAULT 'draft',
    total_views  BIGINT             NOT NULL DEFAULT 0,
    total_likes  BIGINT             NOT NULL DEFAULT 0,
    created_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at   TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_cnt_series_author_id  ON cnt_series (author_id);
CREATE INDEX idx_cnt_series_slug       ON cnt_series (slug);
CREATE INDEX idx_cnt_series_status     ON cnt_series (status);
CREATE INDEX idx_cnt_series_deleted_at ON cnt_series (deleted_at);

CREATE TABLE cnt_series_genres (
    series_id BIGINT NOT NULL REFERENCES cnt_series(id) ON DELETE CASCADE,
    genre_id  BIGINT NOT NULL REFERENCES cnt_genres(id) ON DELETE CASCADE,
    PRIMARY KEY (series_id, genre_id)
);

CREATE TABLE cnt_episodes (
    id             BIGSERIAL          PRIMARY KEY,
    series_id      BIGINT             NOT NULL REFERENCES cnt_series(id) ON DELETE CASCADE,
    title          VARCHAR(512)       NOT NULL,
    episode_number NUMERIC(8,2)       NOT NULL,
    price_coins    INT                NOT NULL DEFAULT 0,
    status         cnt_episode_status NOT NULL DEFAULT 'draft',
    published_at   TIMESTAMP WITH TIME ZONE,
    total_views    BIGINT             NOT NULL DEFAULT 0,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    deleted_at     TIMESTAMP WITH TIME ZONE,
    UNIQUE (series_id, episode_number)
);

CREATE INDEX idx_cnt_episodes_series_id  ON cnt_episodes (series_id);
CREATE INDEX idx_cnt_episodes_status     ON cnt_episodes (status);
CREATE INDEX idx_cnt_episodes_deleted_at ON cnt_episodes (deleted_at);

CREATE TABLE cnt_pages (
    id          BIGSERIAL    PRIMARY KEY,
    episode_id  BIGINT       NOT NULL REFERENCES cnt_episodes(id) ON DELETE CASCADE,
    page_number INT          NOT NULL,
    image_url   VARCHAR(512) NOT NULL,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE (episode_id, page_number)
);

CREATE INDEX idx_cnt_pages_episode_id ON cnt_pages (episode_id);
