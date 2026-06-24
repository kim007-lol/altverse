package config

import (
	"fmt"
	"os"
	"strconv"
)

// Config holds all configuration for the Go services.
type Config struct {
	// Server
	Port string

	// R2 / S3
	R2Endpoint  string
	R2Bucket    string
	R2AccessKey string
	R2SecretKey string
	R2Region    string

	// Cache
	CacheSizeMB int

	// CORS — allowed origins for Flutter dev
	AllowedOrigins string

	// Redis (for tracking event buffer)
	RedisURL string

	// PostgreSQL (for bulk inserts and token validation)
	DatabaseURL string

	// Flusher interval in seconds
	FlushIntervalSec int
}

// Load reads configuration from environment variables with sensible defaults.
func Load() (*Config, error) {
	cfg := &Config{
		Port:             getEnv("PORT", "9000"),
		R2Endpoint:       os.Getenv("R2_ENDPOINT"),
		R2Bucket:         getEnv("R2_BUCKET", "aureader"),
		R2AccessKey:      os.Getenv("R2_ACCESS_KEY"),
		R2SecretKey:      os.Getenv("R2_SECRET_KEY"),
		R2Region:         getEnv("R2_REGION", "auto"),
		CacheSizeMB:      getEnvInt("CACHE_SIZE_MB", 256),
		AllowedOrigins:   getEnv("ALLOWED_ORIGINS", "*"),
		RedisURL:         getEnv("REDIS_URL", "redis://127.0.0.1:6379/0"),
		DatabaseURL:      os.Getenv("DB_URL"),
		FlushIntervalSec: getEnvInt("FLUSH_INTERVAL_SEC", 5),
	}

	if cfg.R2Endpoint == "" {
		return nil, fmt.Errorf("R2_ENDPOINT is required")
	}
	if cfg.R2AccessKey == "" {
		return nil, fmt.Errorf("R2_ACCESS_KEY is required")
	}
	if cfg.R2SecretKey == "" {
		return nil, fmt.Errorf("R2_SECRET_KEY is required")
	}

	return cfg, nil
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	if v := os.Getenv(key); v != "" {
		if i, err := strconv.Atoi(v); err == nil {
			return i
		}
	}
	return fallback
}
