package handler

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"aureader-services/internal/cache"
	"aureader-services/internal/storage"
)

// ImageHandler serves images from R2 with an LRU cache layer.
type ImageHandler struct {
	storage *storage.R2Client
	cache   *cache.LRUCache
}

// NewImageHandler creates a new image handler.
func NewImageHandler(s *storage.R2Client, c *cache.LRUCache) *ImageHandler {
	return &ImageHandler{
		storage: s,
		cache:   c,
	}
}

// ServeHTTP handles GET /images/* requests.
func (h *ImageHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Extract the path after /images/
	path := strings.TrimPrefix(r.URL.Path, "/images/")
	path = strings.TrimPrefix(path, "/")

	if path == "" {
		http.Error(w, `{"error":"path is required"}`, http.StatusBadRequest)
		return
	}

	// 1. Check cache
	if cached := h.cache.Get(path); cached != nil {
		h.serveCached(w, cached, path)
		return
	}

	// 2. Fetch from R2
	ctx := r.Context()
	result, err := h.storage.GetObject(ctx, path)
	if err != nil {
		errMsg := err.Error()
		if strings.Contains(errMsg, "NoSuchKey") || strings.Contains(errMsg, "not found") || strings.Contains(errMsg, "404") {
			http.Error(w, `{"error":"image not found"}`, http.StatusNotFound)
		} else {
			log.Printf("[ERROR] Failed to fetch %s from R2: %v", path, err)
			http.Error(w, `{"error":"internal server error"}`, http.StatusInternalServerError)
		}
		return
	}
	defer result.Body.Close()

	// 3. Read the full body to cache it
	data, err := io.ReadAll(result.Body)
	if err != nil {
		log.Printf("[ERROR] Failed to read body for %s: %v", path, err)
		http.Error(w, `{"error":"failed to read image"}`, http.StatusInternalServerError)
		return
	}

	// 4. Store in cache
	h.cache.Put(path, &cache.CachedImage{
		Data:        data,
		ContentType: result.ContentType,
	})

	// 5. Serve the response
	w.Header().Set("Content-Type", result.ContentType)
	w.Header().Set("Content-Length", strconv.Itoa(len(data)))
	w.Header().Set("Cache-Control", "public, max-age=86400, immutable")
	w.Header().Set("X-Cache", "MISS")
	w.WriteHeader(http.StatusOK)
	w.Write(data)

	log.Printf("[MISS] %s (%s, %s)", path, result.ContentType, formatBytes(int64(len(data))))
}

func (h *ImageHandler) serveCached(w http.ResponseWriter, img *cache.CachedImage, path string) {
	w.Header().Set("Content-Type", img.ContentType)
	w.Header().Set("Content-Length", strconv.Itoa(len(img.Data)))
	w.Header().Set("Cache-Control", "public, max-age=86400, immutable")
	w.Header().Set("X-Cache", "HIT")
	w.WriteHeader(http.StatusOK)
	w.Write(img.Data)
}

// HealthHandler responds to /health checks.
func HealthHandler(startTime time.Time) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		uptime := time.Since(startTime).Round(time.Second)
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status":"ok","service":"aureader-imageproxy","uptime":"%s"}`, uptime)
	}
}

// CacheStatsHandler returns current cache statistics.
func CacheStatsHandler(c *cache.LRUCache) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		items, sizeBytes, maxBytes := c.Stats()
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"items":%d,"size_mb":"%.1f","max_mb":"%.1f","usage_pct":"%.1f%%"}`,
			items,
			float64(sizeBytes)/1024/1024,
			float64(maxBytes)/1024/1024,
			float64(sizeBytes)/float64(maxBytes)*100,
		)
	}
}

func formatBytes(b int64) string {
	if b < 1024 {
		return fmt.Sprintf("%d B", b)
	}
	if b < 1024*1024 {
		return fmt.Sprintf("%.1f KB", float64(b)/1024)
	}
	return fmt.Sprintf("%.1f MB", float64(b)/1024/1024)
}
