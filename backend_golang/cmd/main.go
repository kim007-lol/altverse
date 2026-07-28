package main

import (
	"context"
	"log"
	"net/http"
	"os/signal"
	"syscall"
	"time"

	adminCtrl "aureader/backend/controllers/admin"
	authorCtrl "aureader/backend/controllers/author"
	gamCtrl "aureader/backend/controllers/gamification"
	readerCtrl "aureader/backend/controllers/reader"
	sharedCtrl "aureader/backend/controllers/shared"
	"aureader/backend/config"
	"aureader/backend/internal/database"
	internalRedis "aureader/backend/internal/redis"
	"aureader/backend/middleware"
	"aureader/backend/models"
	"aureader/backend/repositories"
	"aureader/backend/routes"
	"aureader/backend/scheduler"
	"aureader/backend/services"
	"aureader/backend/ws"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func main() {
	cfg := config.Load()

	db := database.Connect(cfg)
	rdb := internalRedis.Connect(cfg)
	defer rdb.Close()

	// Create/sync tables and indexes.
	if err := db.AutoMigrate(&models.AuditLog{}); err != nil {
		log.Printf("[DB] AutoMigrate AuditLog warning: %v", err)
	}
	if err := db.AutoMigrate(&models.User{}, &models.Series{}, &models.Episode{}); err != nil {
		log.Printf("[DB] AutoMigrate indexes warning: %v", err)
	}

	// ── Repositories ──────────────────────────────────────────────────────────
	userRepo    := repositories.NewUserRepository(db)
	seriesRepo  := repositories.NewSeriesRepository(db)
	episodeRepo := repositories.NewEpisodeRepository(db)
	socialRepo  := repositories.NewSocialRepository(db)
	txRepo      := repositories.NewTransactionRepository(db)
	trackRepo   := repositories.NewTrackingRepository(db)
	gamRepo     := repositories.NewGamificationRepository(db)
	notifRepo   := repositories.NewNotificationRepository(db)
	unlockRepo  := repositories.NewEpisodeUnlockRepository(db)

	// ── Services ──────────────────────────────────────────────────────────────
	authSvc        := services.NewAuthService(userRepo)
	userSvc        := services.NewUserService(userRepo)
	seriesSvc      := services.NewSeriesService(seriesRepo)
	episodeSvc     := services.NewEpisodeService(episodeRepo, seriesRepo)
	socialSvc      := services.NewSocialService(socialRepo)
	txSvc          := services.NewTransactionService(txRepo, userRepo)
	trackingSvc    := services.NewTrackingService(trackRepo, episodeRepo)
	xpSvc          := services.NewXPService(gamRepo)
	missionSvc     := services.NewMissionService(gamRepo, userRepo, xpSvc)
	badgeSvc       := services.NewBadgeService(gamRepo, socialRepo, trackRepo)
	leaderboardSvc := services.NewLeaderboardService(gamRepo)
	notifSvc       := services.NewNotificationService(notifRepo, rdb)
	unlockSvc      := services.NewUnlockService(unlockRepo, episodeRepo, seriesRepo, userRepo, notifSvc)

	// ── Image proxy ───────────────────────────────────────────────────────────
	var imageCtrl *sharedCtrl.ImageProxyController
	if cfg.R2Endpoint != "" && cfg.R2AccessKeyID != "" {
		var err error
		imageCtrl, err = sharedCtrl.NewImageProxyController(sharedCtrl.R2Config{
			Endpoint:  cfg.R2Endpoint,
			AccessKey: cfg.R2AccessKeyID,
			SecretKey: cfg.R2SecretAccessKey,
			Region:    "auto",
			Bucket:    cfg.R2BucketName,
		}, 256)
		if err != nil {
			log.Printf("[WARN] Image proxy disabled: %v", err)
		}
	}

	// ── Controllers ───────────────────────────────────────────────────────────
	ctrl := routes.Controllers{
		Auth:       sharedCtrl.NewAuthController(authSvc, userRepo),
		Profile:    readerCtrl.NewProfileController(userSvc),
		Discover:   readerCtrl.NewDiscoverController(seriesSvc, episodeSvc, trackingSvc, userRepo, socialSvc, rdb, db),
		Reading:    readerCtrl.NewReadingController(episodeSvc, trackingSvc, unlockSvc, socialSvc),
		Social:     readerCtrl.NewSocialController(socialSvc, db),
		Wallet:     readerCtrl.NewWalletController(txSvc, userSvc, notifSvc, userRepo, db),
		AuthSeries: authorCtrl.NewSeriesController(seriesSvc),
		AuthEp:     authorCtrl.NewEpisodeController(episodeSvc),
		AdminWd:        adminCtrl.NewWithdrawalController(txSvc, db),
		AdminDash:      adminCtrl.NewDashboardController(db),
		AdminUser:      adminCtrl.NewUserController(db),
		AdminContent:   adminCtrl.NewContentController(db),
		AdminReport:    adminCtrl.NewReportController(db),
		AdminSettings:  adminCtrl.NewSettingsController(),
		AdminCoin:      adminCtrl.NewCoinController(db, userSvc),
		AdminBroadcast: adminCtrl.NewBroadcastController(db, notifSvc),
		AdminAudit:     adminCtrl.NewAuditController(db),
		AdminSeason:    adminCtrl.NewSeasonController(db),
		AdminFinance:   adminCtrl.NewFinanceController(db),
		DB:             db,
		Gam:            gamCtrl.NewController(xpSvc, missionSvc, badgeSvc, leaderboardSvc, db),
		Image:      imageCtrl,
		Notif:      readerCtrl.NewNotificationController(notifSvc),
		Unlock:     readerCtrl.NewUnlockController(unlockSvc),
	}

	// ── Gin engine ────────────────────────────────────────────────────────────
	if cfg.IsProduction() {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(gin.Logger())
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{cfg.AllowedOrigins},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		AllowCredentials: true,
	}))
	r.Use(middleware.DefaultRateLimit())

	routes.Register(r, ctrl)
	r.GET("/health", func(c *gin.Context) { c.JSON(200, gin.H{"status": "ok"}) })

	// ── WebSocket hub ─────────────────────────────────────────────────────────
	wsHub := ws.NewHub(rdb)
	r.GET("/ws", wsHub.GinHandler())
	r.GET("/ws/stats", wsHub.StatsHandler())

	// ── Background services (require context for graceful shutdown) ───────────
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	wsHub.StartRedisSubscriber(ctx)

	flusher := scheduler.NewFlusher(rdb, db, 30)
	flusher.Start(ctx)

	// ── HTTP server ───────────────────────────────────────────────────────────
	srv := &http.Server{Addr: ":" + cfg.AppPort, Handler: r}

	go func() {
		log.Printf("[HTTP] Starting server on port %s", cfg.AppPort)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("[HTTP] Failed to listen and serve: %v", err)
		}
	}()

	<-ctx.Done()
	log.Println("[SHUTDOWN] Signal received, shutting down...")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("[SHUTDOWN] Server forced to shutdown: %v", err)
	}
	log.Println("[SHUTDOWN] Server exited cleanly")
}
