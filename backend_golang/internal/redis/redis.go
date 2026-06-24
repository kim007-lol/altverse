package redis

import (
	"context"
	"fmt"
	"log"
	"time"

	"aureader/backend/config"

	"github.com/redis/go-redis/v9"
)

var Client *redis.Client

// Connect creates and validates a Redis client from config.
func Connect(cfg *config.Config) *redis.Client {
	addr := fmt.Sprintf("%s:%s", cfg.RedisHost, cfg.RedisPort)

	client := redis.NewClient(&redis.Options{
		Addr:         addr,
		Password:     cfg.RedisPassword,
		DB:           cfg.RedisDB,
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
		PoolSize:     10,
		MinIdleConns: 2,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		log.Fatalf("[REDIS] Failed to connect: %v", err)
	}

	log.Printf("[REDIS] ✅ Connected — %s db=%d", addr, cfg.RedisDB)

	Client = client
	return client
}
