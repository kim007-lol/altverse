package middleware

import (
	"strings"

	"aureader/backend/helper"

	"github.com/gin-gonic/gin"
)

// Auth validates the JWT Bearer token and injects user claims into the context.
func Auth() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			helper.Unauthorized(c, "Missing or invalid Authorization header")
			c.Abort()
			return
		}

		tokenStr := strings.TrimPrefix(authHeader, "Bearer ")
		claims, err := helper.ParseToken(tokenStr)
		if err != nil {
			helper.Unauthorized(c, "Invalid or expired token")
			c.Abort()
			return
		}

		// Inject claims into context
		c.Set("user_id", claims.UserID)
		c.Set("user_role", claims.Role)
		c.Set("token_jti", claims.ID)

		c.Next()
	}
}

// GetUserID extracts the authenticated user ID from the Gin context.
func GetUserID(c *gin.Context) uint {
	id, _ := c.Get("user_id")
	if uid, ok := id.(uint); ok {
		return uid
	}
	return 0
}

// GetUserRole extracts the authenticated user role from the Gin context.
func GetUserRole(c *gin.Context) string {
	role, _ := c.Get("user_role")
	if r, ok := role.(string); ok {
		return r
	}
	return ""
}
