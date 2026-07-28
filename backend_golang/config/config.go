package config

import (
	"log"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

// Config holds all application configuration loaded from environment variables.
type Config struct {
	// App
	AppEnv  string
	AppPort string
	AppURL  string

	// Database
	DBHost     string
	DBPort     string
	DBUser     string
	DBPassword string
	DBName     string
	DBSSLMode  string

	// Redis
	RedisHost     string
	RedisPort     string
	RedisPassword string
	RedisDB       int

	// JWT
	JWTSecret            string
	JWTAccessExpMinutes  int
	JWTRefreshExpDays    int

	// Cloudflare R2
	R2AccountID       string
	R2AccessKeyID     string
	R2SecretAccessKey string
	R2BucketName      string
	R2PublicURL       string
	R2Endpoint        string

	// Midtrans
	MidtransMerchantID  string
	MidtransServerKey   string
	MidtransClientKey   string
	MidtransProduction  bool

	// Rate Limiting
	RateLimitRequests int
	RateLimitPeriod   string // "S" = second, "M" = minute, "H" = hour

	// CORS
	AllowedOrigins string
}

var App *Config

// Load reads environment variables and populates the Config struct.
// Call this once at application startup.
func Load() *Config {
	if err := godotenv.Load(); err != nil {
		log.Println("[CONFIG] No .env file found, reading from OS environment")
	}

	App = &Config{
		// App
		AppEnv:  getEnv("APP_ENV", "development"),
		AppPort: getEnv("APP_PORT", "8080"),
		AppURL:  getEnv("APP_URL", "http://localhost:8080"),

		// Database
		DBHost:     getEnv("DB_HOST", "127.0.0.1"),
		DBPort:     getEnv("DB_PORT", "5432"),
		DBUser:     getEnv("DB_USER", "postgres"),
		DBPassword: getEnv("DB_PASSWORD", ""),
		DBName:     getEnv("DB_NAME", "au_reader"),
		DBSSLMode:  getEnv("DB_SSLMODE", "disable"),

		// Redis
		RedisHost:     getEnv("REDIS_HOST", "127.0.0.1"),
		RedisPort:     getEnv("REDIS_PORT", "6379"),
		RedisPassword: getEnv("REDIS_PASSWORD", ""),
		RedisDB:       getEnvInt("REDIS_DB", 0),

		// JWT
		JWTSecret:           getEnv("JWT_SECRET", "change-this-super-secret-key"),
		JWTAccessExpMinutes: getEnvInt("JWT_ACCESS_EXP_MINUTES", 15),
		JWTRefreshExpDays:   getEnvInt("JWT_REFRESH_EXP_DAYS", 7),

		// Cloudflare R2
		R2AccountID:       getEnv("R2_ACCOUNT_ID", ""),
		R2AccessKeyID:     getEnv("R2_ACCESS_KEY_ID", ""),
		R2SecretAccessKey: getEnv("R2_SECRET_ACCESS_KEY", ""),
		R2BucketName:      getEnv("R2_BUCKET_NAME", "aureader"),
		R2PublicURL:       getEnv("R2_PUBLIC_URL", ""),
		R2Endpoint:        getEnv("R2_ENDPOINT", ""),

		// Midtrans
		MidtransMerchantID: getEnv("MIDTRANS_MERCHANT_ID", ""),
		MidtransServerKey:  getEnv("MIDTRANS_SERVER_KEY", ""),
		MidtransClientKey:  getEnv("MIDTRANS_CLIENT_KEY", ""),
		MidtransProduction: getEnvBool("MIDTRANS_IS_PRODUCTION", false),

		// Rate Limiting
		RateLimitRequests: getEnvInt("RATE_LIMIT_REQUESTS", 60),
		RateLimitPeriod:   getEnv("RATE_LIMIT_PERIOD", "M"),

		// CORS
		AllowedOrigins: getEnv("ALLOWED_ORIGINS", "*"),
	}

	return App
}

// IsProduction returns true if the app is running in production mode.
func (c *Config) IsProduction() bool {
	return c.AppEnv == "production"
}

// DBDsn builds the PostgreSQL DSN string for GORM.
func (c *Config) DBDsn() string {
	return "host=" + c.DBHost +
		" user=" + c.DBUser +
		" password=" + c.DBPassword +
		" dbname=" + c.DBName +
		" port=" + c.DBPort +
		" sslmode=" + c.DBSSLMode +
		" TimeZone=Asia/Jakarta"
}

// ─── helpers ───────────────────────────────────────────────────────────────

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	if val := os.Getenv(key); val != "" {
		if i, err := strconv.Atoi(val); err == nil {
			return i
		}
	}
	return fallback
}

func getEnvBool(key string, fallback bool) bool {
	if val := os.Getenv(key); val != "" {
		b, err := strconv.ParseBool(val)
		if err == nil {
			return b
		}
	}
	return fallback
}
