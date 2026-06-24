package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/joho/godotenv"

	"aureader-services/internal/cache"
	"aureader-services/internal/config"
	"aureader-services/internal/handler"
	"aureader-services/internal/storage"
	"aureader-services/internal/worker"
)

func main() {
	// Load .env file (ignore error if not found — env vars might be set directly)
	_ = godotenv.Load()

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("❌ Config error: %v", err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// ─── Initialize R2 storage client ───
	r2, err := storage.NewR2Client(cfg)
	if err != nil {
		log.Fatalf("❌ R2 client error: %v", err)
	}
	log.Printf("✅ R2 client connected to %s (bucket: %s)", cfg.R2Endpoint, cfg.R2Bucket)

	// ─── Initialize LRU cache ───
	imgCache := cache.NewLRUCache(cfg.CacheSizeMB)
	log.Printf("✅ LRU cache initialized (%d MB)", cfg.CacheSizeMB)

	// ─── Initialize Redis ───
	redisClient, err := storage.NewRedisClient(cfg.RedisURL)
	if err != nil {
		log.Printf("⚠️  Redis connection failed: %v (tracking endpoints will be disabled)", err)
		redisClient = nil
	} else {
		log.Printf("✅ Redis connected (%s)", cfg.RedisURL)
	}

	// ─── Initialize PostgreSQL ───
	var pgClient *storage.PostgresClient
	if cfg.DatabaseURL != "" {
		pgClient, err = storage.NewPostgresClient(ctx, cfg.DatabaseURL)
		if err != nil {
			log.Printf("⚠️  PostgreSQL connection failed: %v (tracking endpoints will be disabled)", err)
			pgClient = nil
		} else {
			log.Printf("✅ PostgreSQL connected")
		}
	} else {
		log.Println("⚠️  DB_URL not set — tracking endpoints will be disabled")
	}

	// ─── Create handlers ───
	imageHandler := handler.NewImageHandler(r2, imgCache)
	startTime := time.Now()

	// ─── Setup routes ───
	mux := http.NewServeMux()

	// Phase 1: Image proxy
	mux.HandleFunc("/health", handler.HealthHandler(startTime))
	mux.HandleFunc("/stats", handler.CacheStatsHandler(imgCache))
	mux.Handle("/images/", imageHandler)

	// Phase 2: Tracking (only if Redis + PostgreSQL are available)
	if redisClient != nil && pgClient != nil {
		tracker := handler.NewTrackerHandler(redisClient, pgClient)
		mux.HandleFunc("/track/read", tracker.HandleTrackRead)
		mux.HandleFunc("/track/view", tracker.HandleTrackView)
		log.Println("✅ Tracking endpoints registered (/track/read, /track/view)")

		// Start background flusher
		flusher := worker.NewFlusher(redisClient, pgClient, cfg.FlushIntervalSec)
		flusher.Start(ctx)
		log.Printf("✅ Flusher worker started (interval: %ds)", cfg.FlushIntervalSec)
	} else {
		log.Println("⚠️  Tracking endpoints are disabled (Redis or PostgreSQL unavailable)")
	}

	// Phase 3: WebSocket for real-time notifications
	if redisClient != nil && pgClient != nil {
		wsHub := handler.NewWSHub(redisClient, pgClient)
		mux.HandleFunc("/ws", wsHub.HandleWS)
		mux.HandleFunc("/ws-stats", handler.WSStatsHandler(wsHub))
		log.Println("✅ WebSocket endpoint registered (/ws)")

		// Start Redis pub/sub subscriber for notifications
		wsHub.StartRedisSubscriber(ctx)
		log.Println("✅ Redis notification subscriber started")
	}

	// Phase 4: Background image processor
	if redisClient != nil && pgClient != nil {
		imgProcessor := worker.NewImageProcessor(redisClient, r2, pgClient)
		imgProcessor.Start(ctx)
		log.Println("✅ Image processor worker started (channel: image:process)")
	}

	// Wrap with CORS middleware
	corsHandler := corsMiddleware(cfg.AllowedOrigins, mux)

	// ─── Start server ───
	addr := ":" + cfg.Port
	if os.Getenv("HOST") != "" {
		addr = os.Getenv("HOST") + addr
	} else {
		addr = "0.0.0.0" + addr
	}

	log.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	log.Printf("🚀 AU Reader Go Services running on http://%s", addr)
	log.Printf("   Health:    http://%s/health", addr)
	log.Printf("   Stats:     http://%s/stats", addr)
	log.Printf("   Images:    http://%s/images/<path>", addr)
	if redisClient != nil && pgClient != nil {
		log.Printf("   Track Read: POST http://%s/track/read", addr)
		log.Printf("   Track View: POST http://%s/track/view", addr)
		log.Printf("   WebSocket:  ws://%s/ws?token=<token>", addr)
		log.Printf("   WS Stats:   http://%s/ws-stats", addr)
	}
	log.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	server := &http.Server{
		Addr:         addr,
		Handler:      corsHandler,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// ─── Graceful shutdown ───
	go func() {
		sigCh := make(chan os.Signal, 1)
		signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
		<-sigCh

		log.Println("🛑 Shutdown signal received...")
		cancel() // stops the flusher (which will do a final flush)

		shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer shutdownCancel()

		if err := server.Shutdown(shutdownCtx); err != nil {
			log.Printf("Server shutdown error: %v", err)
		}
	}()

	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("❌ Server error: %v", err)
	}

	log.Println("👋 Server stopped gracefully")
}

// corsMiddleware adds CORS headers so Flutter apps can fetch images cross-origin.
func corsMiddleware(allowedOrigins string, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", allowedOrigins)
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Accept, Authorization")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func init() {
	log.SetFlags(log.Ldate | log.Ltime | log.Lmicroseconds)
	fmt.Println()
	fmt.Println("  ╔══════════════════════════════════════╗")
	fmt.Println("  ║   AU Reader — Go Services v4.0       ║")
	fmt.Println("  ╚══════════════════════════════════════╝")
	fmt.Println()
}
