package worker

import (
	"context"
	"encoding/json"
	"log"
	"time"

	"aureader-services/internal/storage"
)

// Flusher periodically drains tracking events from Redis and bulk-inserts them into PostgreSQL.
type Flusher struct {
	redis    *storage.RedisClient
	postgres *storage.PostgresClient
	interval time.Duration
	batchMax int64
}

// NewFlusher creates a new flusher with the given interval.
func NewFlusher(r *storage.RedisClient, pg *storage.PostgresClient, intervalSec int) *Flusher {
	return &Flusher{
		redis:    r,
		postgres: pg,
		interval: time.Duration(intervalSec) * time.Second,
		batchMax: 500, // max events to process per tick
	}
}

// Start begins the flusher loop in a goroutine. Call this once at startup.
func (f *Flusher) Start(ctx context.Context) {
	go func() {
		log.Printf("[FLUSHER] Started (interval: %s, batch max: %d)", f.interval, f.batchMax)

		ticker := time.NewTicker(f.interval)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				log.Println("[FLUSHER] Shutting down...")
				// Final flush before exit
				f.flush(context.Background())
				return
			case <-ticker.C:
				f.flush(ctx)
			}
		}
	}()
}

// flush processes all pending events from Redis.
func (f *Flusher) flush(ctx context.Context) {
	f.flushReads(ctx)
	f.flushViews(ctx)
}

// flushReads drains the tracking:reads list and bulk-upserts into reading_histories.
func (f *Flusher) flushReads(ctx context.Context) {
	items, err := f.redis.PopAll(ctx, "tracking:reads", f.batchMax)
	if err != nil {
		log.Printf("[FLUSHER] Error popping reads: %v", err)
		return
	}
	if len(items) == 0 {
		return
	}

	events := make([]storage.ReadEvent, 0, len(items))
	for _, item := range items {
		var e storage.ReadEvent
		if err := json.Unmarshal([]byte(item), &e); err != nil {
			log.Printf("[FLUSHER] Skipping malformed read event: %v", err)
			continue
		}
		events = append(events, e)
	}

	if len(events) == 0 {
		return
	}

	if err := f.postgres.BulkUpsertReads(ctx, events); err != nil {
		log.Printf("[FLUSHER] ❌ Failed to bulk upsert reads: %v", err)
		// TODO: re-push failed events back to Redis for retry
		return
	}

	log.Printf("[FLUSHER] ✅ Flushed %d read events to database", len(events))
}

// flushViews drains the tracking:views list and bulk-inserts into views_log.
func (f *Flusher) flushViews(ctx context.Context) {
	items, err := f.redis.PopAll(ctx, "tracking:views", f.batchMax)
	if err != nil {
		log.Printf("[FLUSHER] Error popping views: %v", err)
		return
	}
	if len(items) == 0 {
		return
	}

	events := make([]storage.ViewEvent, 0, len(items))
	for _, item := range items {
		var e storage.ViewEvent
		if err := json.Unmarshal([]byte(item), &e); err != nil {
			log.Printf("[FLUSHER] Skipping malformed view event: %v", err)
			continue
		}
		events = append(events, e)
	}

	if len(events) == 0 {
		return
	}

	// Insert view logs
	if err := f.postgres.BulkInsertViews(ctx, events); err != nil {
		log.Printf("[FLUSHER] ❌ Failed to bulk insert views: %v", err)
		return
	}

	// Increment counters
	if err := f.postgres.IncrementViewCounts(ctx, events); err != nil {
		log.Printf("[FLUSHER] ⚠️  Failed to increment view counts: %v", err)
	}

	log.Printf("[FLUSHER] ✅ Flushed %d view events to database", len(events))
}
