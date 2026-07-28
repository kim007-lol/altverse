package middleware

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"strings"

	"aureader/backend/models"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// AdminAudit logs every non-GET admin action after the handler completes.
// It reads the authenticated user from the JWT (set by Auth middleware) and
// persists a row to adm_audit_logs. Failures are silent — audit must not
// break the actual request.
func AdminAudit(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Only log mutating operations.
		if c.Request.Method == http.MethodGet || c.Request.Method == http.MethodOptions {
			c.Next()
			return
		}

		// Capture request body for the detail field (limit 1 KB to avoid bloat).
		var bodySnippet string
		if c.Request.Body != nil {
			bodyBytes, _ := io.ReadAll(io.LimitReader(c.Request.Body, 1024))
			c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))
			bodySnippet = string(bodyBytes)
		}

		c.Next() // run the actual handler

		adminID := uint64(GetUserID(c))
		if adminID == 0 {
			return
		}

		// Derive a human-readable action from method + path.
		action := deriveAction(c.Request.Method, c.FullPath())
		targetType, targetID := extractTarget(c.FullPath(), c)

		// Fetch admin name (best-effort).
		var adminName string
		db.Table("usr_users").Select("name").Where("id = ?", adminID).Scan(&adminName)

		log := models.AuditLog{
			AdminID:    adminID,
			AdminName:  adminName,
			Action:     action,
			TargetType: targetType,
			TargetID:   targetID,
			Detail:     bodySnippet,
			IPAddress:  c.ClientIP(),
			StatusCode: c.Writer.Status(),
		}
		// Fire-and-forget — do not block response.
		go db.Create(&log)
	}
}

func deriveAction(method, path string) string {
	parts := strings.Split(strings.Trim(path, "/"), "/")
	resource := "resource"
	if len(parts) >= 3 {
		resource = parts[2] // e.g. "users", "reports", "withdrawals"
	}
	switch method {
	case http.MethodPost:
		return fmt.Sprintf("create_%s", resource)
	case http.MethodPut:
		return fmt.Sprintf("update_%s", resource)
	case http.MethodDelete:
		return fmt.Sprintf("delete_%s", resource)
	default:
		return fmt.Sprintf("%s_%s", strings.ToLower(method), resource)
	}
}

func extractTarget(fullPath string, c *gin.Context) (targetType, targetID string) {
	parts := strings.Split(strings.Trim(fullPath, "/"), "/")
	if len(parts) >= 3 {
		targetType = parts[2] // e.g. "users"
	}
	// Try common param names.
	for _, param := range []string{"id", "userId", "reportId", "seasonId"} {
		if v := c.Param(param); v != "" {
			targetID = strings.TrimPrefix(v, "/")
			return
		}
	}
	return
}
