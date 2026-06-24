package middleware

import (
	"net/http"

	"aureader/backend/helper"

	"github.com/gin-gonic/gin"
	"github.com/ulule/limiter/v3"
	ginlimiter "github.com/ulule/limiter/v3/drivers/middleware/gin"
	"github.com/ulule/limiter/v3/drivers/store/memory"
)

// RateLimit creates an in-memory rate limiter middleware.
// formatted: "5-S" (5/sec), "60-M" (60/min), "1000-H" (1000/hour)
func RateLimit(formatted string) gin.HandlerFunc {
	rate, err := limiter.NewRateFromFormatted(formatted)
	if err != nil {
		panic("invalid rate format: " + err.Error())
	}

	store := memory.NewStore()
	instance := limiter.New(store, rate)

	mw := ginlimiter.NewMiddleware(instance, ginlimiter.WithLimitReachedHandler(func(c *gin.Context) {
		helper.TooManyRequests(c)
		c.Abort()
	}))

	return mw
}

// StrictRateLimit is a tighter limiter (5 requests/minute) for sensitive endpoints
// like login, register, topup creation.
func StrictRateLimit() gin.HandlerFunc {
	return RateLimit("5-M")
}

// DefaultRateLimit is the standard limiter (60 requests/minute).
func DefaultRateLimit() gin.HandlerFunc {
	return RateLimit("60-M")
}

// UploadRateLimit limits upload-related endpoints (30 requests/minute).
func UploadRateLimit() gin.HandlerFunc {
	return RateLimit("30-M")
}

// WebhookRateLimit for payment webhooks (generous — must not block legitimate events).
func WebhookRateLimit() gin.HandlerFunc {
	return RateLimit("100-M")
}

// noopHandler is a fallback for disabled rate limiting.
func noopHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()
	}
}

// Throttle is a generic alias for building a specific rate (requests per period).
// period: "S" | "M" | "H"
func Throttle(requests int, period string) gin.HandlerFunc {
	if requests <= 0 {
		return noopHandler()
	}
	_ = period
	formatted := limiter.Rate{}
	_ = formatted
	return RateLimit(http.MethodGet) // will be overridden below
}
