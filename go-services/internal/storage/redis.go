package storage

import (
	"context"
	"fmt"
	"log"

	"github.com/redis/go-redis/v9"
)

// RedisClient wraps a go-redis client for the tracking buffer.
type RedisClient struct {
	client *redis.Client
}

// NewRedisClient creates a Redis connection from a URL like "redis://127.0.0.1:6379/0".
func NewRedisClient(redisURL string) (*RedisClient, error) {
	opts, err := redis.ParseURL(redisURL)
	if err != nil {
		return nil, fmt.Errorf("invalid REDIS_URL: %w", err)
	}

	client := redis.NewClient(opts)

	// Test connection
	ctx := context.Background()
	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("redis ping failed: %w", err)
	}

	return &RedisClient{client: client}, nil
}

// Push appends a JSON payload to a Redis list.
func (r *RedisClient) Push(ctx context.Context, key string, payload string) error {
	return r.client.RPush(ctx, key, payload).Err()
}

// PopAll atomically pops all elements from a Redis list using LRANGE + DEL.
// This avoids losing data if the flusher crashes mid-processing.
func (r *RedisClient) PopAll(ctx context.Context, key string, maxItems int64) ([]string, error) {
	pipe := r.client.Pipeline()

	// Get up to maxItems from the list
	lrangeCmd := pipe.LRange(ctx, key, 0, maxItems-1)
	// Trim the list to remove the items we just read
	pipe.LTrim(ctx, key, maxItems, -1)

	_, err := pipe.Exec(ctx)
	if err != nil && err != redis.Nil {
		return nil, fmt.Errorf("redis pipeline error: %w", err)
	}

	items := lrangeCmd.Val()
	if len(items) > 0 {
		log.Printf("[REDIS] Popped %d items from %s", len(items), key)
	}

	return items, nil
}

// Subscribe listens on a Redis pub/sub channel and calls handler for each message.
// This blocks until the context is cancelled or an error occurs.
func (r *RedisClient) Subscribe(ctx context.Context, channel string, handler func(payload string)) error {
	sub := r.client.Subscribe(ctx, channel)
	defer sub.Close()

	ch := sub.Channel()
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case msg, ok := <-ch:
			if !ok {
				return fmt.Errorf("subscription channel closed")
			}
			handler(msg.Payload)
		}
	}
}

// Publish sends a message to a Redis pub/sub channel.
func (r *RedisClient) Publish(ctx context.Context, channel string, payload string) error {
	return r.client.Publish(ctx, channel, payload).Err()
}

// Ping checks if Redis is alive.
func (r *RedisClient) Ping(ctx context.Context) error {
	return r.client.Ping(ctx).Err()
}

// Close shuts down the Redis client.
func (r *RedisClient) Close() error {
	return r.client.Close()
}
