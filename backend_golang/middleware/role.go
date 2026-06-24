package middleware

import (
	"aureader/backend/helper"

	"github.com/gin-gonic/gin"
)

// ReaderOnly blocks non-reader roles (authors cannot access reader-only endpoints).
func ReaderOnly() gin.HandlerFunc {
	return func(c *gin.Context) {
		role := GetUserRole(c)
		if role != "reader" {
			helper.Forbidden(c, "This endpoint is for readers only")
			c.Abort()
			return
		}
		c.Next()
	}
}

// AuthorOnly blocks non-author roles.
func AuthorOnly() gin.HandlerFunc {
	return func(c *gin.Context) {
		role := GetUserRole(c)
		if role != "author" {
			helper.Forbidden(c, "This endpoint is for authors only")
			c.Abort()
			return
		}
		c.Next()
	}
}

// AdminOnly blocks non-admin roles.
func AdminOnly() gin.HandlerFunc {
	return func(c *gin.Context) {
		role := GetUserRole(c)
		if role != "admin" {
			helper.Forbidden(c, "This endpoint is for admins only")
			c.Abort()
			return
		}
		c.Next()
	}
}

// ReaderOrAuthor allows both readers and authors (blocks admin-only actions).
func ReaderOrAuthor() gin.HandlerFunc {
	return func(c *gin.Context) {
		role := GetUserRole(c)
		if role != "reader" && role != "author" {
			helper.Forbidden(c, "Access denied")
			c.Abort()
			return
		}
		c.Next()
	}
}
