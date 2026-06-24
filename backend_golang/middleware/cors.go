package middleware

import (
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

// CORS sets up Cross-Origin Resource Sharing headers.
// In production set AllowOrigins to your specific domains.
func CORS(allowedOrigins string) gin.HandlerFunc {
	origins := []string{"*"}
	if allowedOrigins != "" && allowedOrigins != "*" {
		origins = []string{allowedOrigins}
	}

	return cors.New(cors.Config{
		AllowOrigins:     origins,
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization", "Accept", "X-Requested-With"},
		ExposeHeaders:    []string{"Content-Length", "Content-Disposition"},
		AllowCredentials: allowedOrigins != "*",
		MaxAge:           12 * time.Hour,
	})
}
