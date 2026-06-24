package controllers

import (
	"errors"

	"aureader/backend/errorhandler"
	"aureader/backend/helper"

	"github.com/gin-gonic/gin"
)

// HandleErr maps an AppError to the correct HTTP response.
// Falls back to 500 for unknown errors.
func HandleErr(c *gin.Context, err error) {
	var appErr *errorhandler.AppError
	if errors.As(err, &appErr) {
		c.JSON(appErr.Code, helper.Response{
			Success: false,
			Message: appErr.Message,
		})
		return
	}
	helper.InternalError(c, "")
}

// PaginationParams extracts page/per_page from query with safe defaults.
func PaginationParams(c *gin.Context) (page, perPage int) {
	page = max(1, intQuery(c, "page", 1))
	perPage = clamp(intQuery(c, "per_page", 20), 1, 50)
	return
}

func intQuery(c *gin.Context, key string, def int) int {
	v := c.DefaultQuery(key, "")
	if v == "" {
		return def
	}
	n := 0
	for _, ch := range v {
		if ch < '0' || ch > '9' {
			return def
		}
		n = n*10 + int(ch-'0')
	}
	return n
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func clamp(v, lo, hi int) int {
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}
