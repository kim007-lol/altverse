package storage

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// PostgresClient wraps a pgx connection pool.
type PostgresClient struct {
	pool *pgxpool.Pool
}

// ReadEvent represents a reading progress event to be bulk-inserted.
type ReadEvent struct {
	UserID    int64   `json:"user_id"`
	SeriesID  int64   `json:"series_id"`
	EpisodeID int64   `json:"episode_id"`
	LastPage  int     `json:"last_page"`
	Progress  float64 `json:"progress"`
}

// ViewEvent represents a view log entry.
type ViewEvent struct {
	UserID    int64  `json:"user_id"`
	EpisodeID int64  `json:"episode_id"`
	SeriesID  int64  `json:"series_id"`
	ViewDate  string `json:"view_date"` // YYYY-MM-DD
}

// NewPostgresClient creates a new connection pool from a database URL.
func NewPostgresClient(ctx context.Context, dbURL string) (*PostgresClient, error) {
	poolCfg, err := pgxpool.ParseConfig(dbURL)
	if err != nil {
		return nil, fmt.Errorf("invalid DB_URL: %w", err)
	}

	poolCfg.MaxConns = 10
	poolCfg.MinConns = 2

	pool, err := pgxpool.NewWithConfig(ctx, poolCfg)
	if err != nil {
		return nil, fmt.Errorf("failed to create pool: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("database ping failed: %w", err)
	}

	return &PostgresClient{pool: pool}, nil
}

// ValidateToken checks if a Bearer token (plain text) matches a hashed token
// in the personal_access_tokens table. Returns the tokenable_id (user ID).
//
// Laravel Sanctum stores tokens as SHA-256 hashes of the plain-text token.
// The full token sent by Flutter looks like "1|abcdef123..." where "1" is the
// token ID and "abcdef123..." is the plain token. We hash the plain part and
// compare it against the stored hash.
func (p *PostgresClient) ValidateToken(ctx context.Context, bearerToken string) (int64, error) {
	// Strip "Bearer " prefix if present
	token := strings.TrimPrefix(bearerToken, "Bearer ")
	token = strings.TrimSpace(token)

	// Split "id|plainToken" format
	parts := strings.SplitN(token, "|", 2)
	if len(parts) != 2 {
		return 0, fmt.Errorf("invalid token format")
	}

	plainToken := parts[1]

	// Hash it with SHA-256 (same as Laravel Sanctum)
	hash := sha256.Sum256([]byte(plainToken))
	hashedToken := hex.EncodeToString(hash[:])

	var userID int64
	err := p.pool.QueryRow(ctx,
		`SELECT tokenable_id FROM personal_access_tokens
		 WHERE token = $1
		   AND (expires_at IS NULL OR expires_at > NOW())`,
		hashedToken,
	).Scan(&userID)

	if err != nil {
		return 0, fmt.Errorf("token not found or expired: %w", err)
	}

	return userID, nil
}

// BulkUpsertReads inserts or updates reading history entries in batch.
// Uses ON CONFLICT to upsert (update if user+series+episode already exists).
func (p *PostgresClient) BulkUpsertReads(ctx context.Context, events []ReadEvent) error {
	if len(events) == 0 {
		return nil
	}

	// Build bulk upsert query
	var sb strings.Builder
	sb.WriteString(`INSERT INTO reading_histories (user_id, series_id, episode_id, last_page, progress, read_at, created_at, updated_at)
VALUES `)

	args := make([]interface{}, 0, len(events)*5)
	for i, e := range events {
		if i > 0 {
			sb.WriteString(", ")
		}
		offset := i * 5
		sb.WriteString(fmt.Sprintf("($%d, $%d, $%d, $%d, $%d, NOW(), NOW(), NOW())",
			offset+1, offset+2, offset+3, offset+4, offset+5))
		args = append(args, e.UserID, e.SeriesID, e.EpisodeID, e.LastPage, e.Progress)
	}

	sb.WriteString(` ON CONFLICT (user_id, series_id, episode_id)
DO UPDATE SET last_page = EXCLUDED.last_page,
              progress = GREATEST(reading_histories.progress, EXCLUDED.progress),
              read_at = NOW(),
              updated_at = NOW()`)

	_, err := p.pool.Exec(ctx, sb.String(), args...)
	if err != nil {
		return fmt.Errorf("bulk upsert reads failed: %w", err)
	}

	log.Printf("[DB] Upserted %d reading history entries", len(events))
	return nil
}

// BulkInsertViews inserts view log entries, skipping duplicates for same user+episode+date.
func (p *PostgresClient) BulkInsertViews(ctx context.Context, events []ViewEvent) error {
	if len(events) == 0 {
		return nil
	}

	var sb strings.Builder
	sb.WriteString(`INSERT INTO views_log (user_id, episode_id, series_id, viewed_date, created_at, updated_at)
VALUES `)

	args := make([]interface{}, 0, len(events)*4)
	for i, e := range events {
		if i > 0 {
			sb.WriteString(", ")
		}
		offset := i * 4
		sb.WriteString(fmt.Sprintf("($%d, $%d, $%d, $%d, NOW(), NOW())",
			offset+1, offset+2, offset+3, offset+4))
		args = append(args, e.UserID, e.EpisodeID, e.SeriesID, e.ViewDate)
	}

	sb.WriteString(` ON CONFLICT DO NOTHING`)

	_, err := p.pool.Exec(ctx, sb.String(), args...)
	if err != nil {
		return fmt.Errorf("bulk insert views failed: %w", err)
	}

	log.Printf("[DB] Inserted %d view log entries", len(events))
	return nil
}

// IncrementViewCounts updates episode view_count and series total_views
// for episodes that got new views.
func (p *PostgresClient) IncrementViewCounts(ctx context.Context, events []ViewEvent) error {
	if len(events) == 0 {
		return nil
	}

	// Deduplicate by episode_id
	episodeSet := make(map[int64]int64) // episode_id -> series_id
	for _, e := range events {
		episodeSet[e.EpisodeID] = e.SeriesID
	}

	now := time.Now()
	for epID, seriesID := range episodeSet {
		_, _ = p.pool.Exec(ctx,
			`UPDATE episodes SET view_count = view_count + 1 WHERE id = $1`, epID)
		_, _ = p.pool.Exec(ctx,
			`UPDATE series SET total_views = total_views + 1 WHERE id = $1`, seriesID)
		_ = now // suppress unused
	}

	return nil
}

// Exec executes a query that doesn't return rows (UPDATE, DELETE, etc.).
func (p *PostgresClient) Exec(ctx context.Context, sql string, args ...interface{}) (int64, error) {
	ct, err := p.pool.Exec(ctx, sql, args...)
	if err != nil {
		return 0, err
	}
	return ct.RowsAffected(), nil
}

// Ping checks if the database is alive.
func (p *PostgresClient) Ping(ctx context.Context) error {
	return p.pool.Ping(ctx)
}

// Close shuts down the connection pool.
func (p *PostgresClient) Close() {
	p.pool.Close()
}
