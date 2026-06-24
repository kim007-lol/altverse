package scheduler

import (
	"context"
	"encoding/json"
	"log"
	"time"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"aureader/backend/models"

	"github.com/redis/go-redis/v9"
)

// ReadEvent mirrors the JSON pushed to tracking:reads.
type ReadEvent struct {
	UserID             uint64  `json:"user_id"`
	EpisodeID          uint64  `json:"episode_id"`
	LastReadPage       int     `json:"last_read_page"`
	ProgressPercentage float64 `json:"progress_percentage"`
}

// ViewEvent mirrors the JSON pushed to tracking:views.
type ViewEvent struct {
	EpisodeID uint64  `json:"episode_id"`
	UserID    *uint64 `json:"user_id,omitempty"`
	IPAddress string  `json:"ip_address,omitempty"`
}

const batchMax = int64(500)

// Flusher periodically drains tracking events from Redis and bulk-writes to PostgreSQL.
type Flusher struct {
	redis    *redis.Client
	db       *gorm.DB
	interval time.Duration
}

func NewFlusher(rdb *redis.Client, db *gorm.DB, intervalSec int) *Flusher {
	return &Flusher{
		redis:    rdb,
		db:       db,
		interval: time.Duration(intervalSec) * time.Second,
	}
}

// Start launches the flush loop as a goroutine.
func (f *Flusher) Start(ctx context.Context) {
	go func() {
		log.Printf("[FLUSHER] Started (interval: %s, batch: %d)", f.interval, batchMax)
		ticker := time.NewTicker(f.interval)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				log.Println("[FLUSHER] Shutting down — final flush...")
				f.flush(context.Background())
				return
			case <-ticker.C:
				f.flush(ctx)
			}
		}
	}()
}

func (f *Flusher) flush(ctx context.Context) {
	f.flushReads(ctx)
	f.flushViews(ctx)
}

func (f *Flusher) flushReads(ctx context.Context) {
	items, err := popAll(ctx, f.redis, "tracking:reads", batchMax)
	if err != nil || len(items) == 0 {
		return
	}

	records := make([]models.ReadingHistory, 0, len(items))
	now := time.Now()
	for _, item := range items {
		var e ReadEvent
		if err := json.Unmarshal([]byte(item), &e); err != nil {
			continue
		}
		records = append(records, models.ReadingHistory{
			UserID:             e.UserID,
			EpisodeID:          e.EpisodeID,
			LastReadPage:       e.LastReadPage,
			ProgressPercentage: e.ProgressPercentage,
			LastReadAt:         now,
		})
	}
	if len(records) == 0 {
		return
	}

	err = f.db.WithContext(ctx).
		Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "user_id"}, {Name: "episode_id"}},
			DoUpdates: clause.AssignmentColumns([]string{"last_read_page", "progress_percentage", "last_read_at", "updated_at"}),
		}).
		Create(&records).Error
	if err != nil {
		log.Printf("[FLUSHER] ❌ reads upsert failed: %v", err)
		return
	}
	log.Printf("[FLUSHER] ✅ Flushed %d read events", len(records))
}

func (f *Flusher) flushViews(ctx context.Context) {
	items, err := popAll(ctx, f.redis, "tracking:views", batchMax)
	if err != nil || len(items) == 0 {
		return
	}

	logs := make([]models.ViewLog, 0, len(items))
	now := time.Now()
	episodeIDs := map[uint64]struct{}{}

	for _, item := range items {
		var e ViewEvent
		if err := json.Unmarshal([]byte(item), &e); err != nil {
			continue
		}
		vl := models.ViewLog{EpisodeID: e.EpisodeID, UserID: e.UserID, ViewedAt: now}
		if e.IPAddress != "" {
			vl.IPAddress = &e.IPAddress
		}
		logs = append(logs, vl)
		episodeIDs[e.EpisodeID] = struct{}{}
	}
	if len(logs) == 0 {
		return
	}

	if err := f.db.WithContext(ctx).Create(&logs).Error; err != nil {
		log.Printf("[FLUSHER] ❌ views insert failed: %v", err)
		return
	}

	// Bulk increment view counters
	ids := make([]uint64, 0, len(episodeIDs))
	for id := range episodeIDs {
		ids = append(ids, id)
	}
	_ = f.db.WithContext(ctx).
		Model(&models.Episode{}).
		Where("id IN ?", ids).
		UpdateColumn("total_views", gorm.Expr("total_views + 1")).Error

	log.Printf("[FLUSHER] ✅ Flushed %d view events", len(logs))
}

// popAll atomically pops up to maxItems from a Redis list.
func popAll(ctx context.Context, rdb *redis.Client, key string, maxItems int64) ([]string, error) {
	pipe := rdb.Pipeline()
	lrangeCmd := pipe.LRange(ctx, key, 0, maxItems-1)
	pipe.LTrim(ctx, key, maxItems, -1)
	if _, err := pipe.Exec(ctx); err != nil && err != redis.Nil {
		return nil, err
	}
	return lrangeCmd.Val(), nil
}
