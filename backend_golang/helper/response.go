package helper

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// ─── Response structs ──────────────────────────────────────────────────────

// Response is the standard JSON envelope for all API responses.
type Response struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
	Errors  interface{} `json:"errors,omitempty"`
}

// PaginatedResponse wraps a paginated list with metadata.
type PaginatedResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
	Meta    *PaginaMeta `json:"meta"`
}

// PaginaMeta holds pagination metadata.
type PaginaMeta struct {
	Page     int   `json:"page"`
	PerPage  int   `json:"per_page"`
	Total    int64 `json:"total"`
	LastPage int   `json:"last_page"`
}

// ─── Success helpers ────────────────────────────────────────────────────────

// OK sends a 200 response with data.
func OK(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Success: true,
		Message: message,
		Data:    data,
	})
}

// Created sends a 201 response with data.
func Created(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusCreated, Response{
		Success: true,
		Message: message,
		Data:    data,
	})
}

// NoContent sends a 200 with a success message and no data.
func NoContent(c *gin.Context, message string) {
	c.JSON(http.StatusOK, Response{
		Success: true,
		Message: message,
	})
}

// Paginated sends a 200 response with paginated data.
func Paginated(c *gin.Context, message string, data interface{}, page, perPage int, total int64) {
	lastPage := 1
	if perPage > 0 && total > 0 {
		lastPage = int((total + int64(perPage) - 1) / int64(perPage))
	}

	c.JSON(http.StatusOK, PaginatedResponse{
		Success: true,
		Message: message,
		Data:    data,
		Meta: &PaginaMeta{
			Page:     page,
			PerPage:  perPage,
			Total:    total,
			LastPage: lastPage,
		},
	})
}

// ─── Error helpers ──────────────────────────────────────────────────────────

// BadRequest sends a 400 response.
func BadRequest(c *gin.Context, message string, errs interface{}) {
	c.JSON(http.StatusBadRequest, Response{
		Success: false,
		Message: message,
		Errors:  errs,
	})
}

// Unauthorized sends a 401 response.
func Unauthorized(c *gin.Context, message string) {
	if message == "" {
		message = "Unauthorized"
	}
	c.JSON(http.StatusUnauthorized, Response{
		Success: false,
		Message: message,
	})
}

// Forbidden sends a 403 response.
func Forbidden(c *gin.Context, message string) {
	if message == "" {
		message = "Forbidden — you don't have permission"
	}
	c.JSON(http.StatusForbidden, Response{
		Success: false,
		Message: message,
	})
}

// NotFound sends a 404 response.
func NotFound(c *gin.Context, message string) {
	if message == "" {
		message = "Resource not found"
	}
	c.JSON(http.StatusNotFound, Response{
		Success: false,
		Message: message,
	})
}

// Conflict sends a 409 response.
func Conflict(c *gin.Context, message string) {
	c.JSON(http.StatusConflict, Response{
		Success: false,
		Message: message,
	})
}

// UnprocessableEntity sends a 422 response with validation errors.
func UnprocessableEntity(c *gin.Context, errs interface{}) {
	c.JSON(http.StatusUnprocessableEntity, Response{
		Success: false,
		Message: "Validation failed",
		Errors:  errs,
	})
}

// TooManyRequests sends a 429 response.
func TooManyRequests(c *gin.Context) {
	c.JSON(http.StatusTooManyRequests, Response{
		Success: false,
		Message: "Too many requests, please slow down",
	})
}

// InternalError sends a 500 response.
func InternalError(c *gin.Context, message string) {
	if message == "" {
		message = "Internal server error"
	}
	c.JSON(http.StatusInternalServerError, Response{
		Success: false,
		Message: message,
	})
}

// ServiceUnavailable sends a 503 response.
func ServiceUnavailable(c *gin.Context, message string) {
	c.JSON(http.StatusServiceUnavailable, Response{
		Success: false,
		Message: message,
	})
}
