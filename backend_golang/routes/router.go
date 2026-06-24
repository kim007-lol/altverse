package routes

import (
	"aureader/backend/config"
	"aureader/backend/helper"
	"aureader/backend/middleware"

	"github.com/gin-gonic/gin"
)

// SetupRouter initializes the Gin engine and registers all routes.
func SetupRouter(cfg *config.Config) *gin.Engine {
	if cfg.IsProduction() {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.New()

	// Global middlewares
	r.Use(gin.Recovery())
	r.Use(middleware.CORS(cfg.AllowedOrigins))

	// Health check
	r.GET("/health", func(c *gin.Context) {
		helper.OK(c, "Service is healthy", nil)
	})

	// API V1 Group
	v1 := r.Group("/api/v1")
	{
		// TODO: Register domain-specific routes here
		_ = v1
	}

	// 404 Handler
	r.NoRoute(func(c *gin.Context) {
		helper.NotFound(c, "Endpoint not found")
	})

	return r
}
