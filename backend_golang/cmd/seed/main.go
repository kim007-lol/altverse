package main

import (
	"fmt"
	"log"
	"os"

	"aureader/backend/config"
	"aureader/backend/internal/database"

	"github.com/joho/godotenv"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	if err := godotenv.Load("../../.env"); err != nil {
		log.Println("[seed] No .env found, using OS env")
	}

	cfg := config.Load()
	db := database.Connect(cfg)

	name := envOr("ADMIN_NAME", "Super Admin")
	email := envOr("ADMIN_EMAIL", "admin@aureader.com")
	password := envOr("ADMIN_PASSWORD", "Admin@1234")

	hash, err := bcrypt.GenerateFromPassword([]byte(password), 12)
	if err != nil {
		log.Fatalf("[seed] bcrypt error: %v", err)
	}

	sql := `
		INSERT INTO usr_users (name, email, password, role, level, exp_points, coins, author_tier, theme_preference, created_at, updated_at)
		VALUES (?, ?, ?, 'admin', 1, 0, 0, 'bronze', 'dark', NOW(), NOW())
		ON CONFLICT (email) DO UPDATE SET
			name     = EXCLUDED.name,
			password = EXCLUDED.password,
			role     = 'admin'
	`
	if err := db.Exec(sql, name, email, string(hash)).Error; err != nil {
		log.Fatalf("[seed] insert failed: %v", err)
	}

	fmt.Printf("[seed] Admin user ready:\n  email   : %s\n  password: %s\n", email, password)
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
