package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"aureader-services/internal/storage"
)

// TrackerHandler handles tracking endpoints (POST /track/read, /track/view).
type TrackerHandler struct {
	redis    *storage.RedisClient
	postgres *storage.PostgresClient
}

// NewTrackerHandler creates a new tracker handler.
func NewTrackerHandler(r *storage.RedisClient, pg *storage.PostgresClient) *TrackerHandler {
	return &TrackerHandler{
		redis:    r,
		postgres: pg,
	}
}

// trackReadRequest is the JSON body for POST /track/read.
type trackReadRequest struct {
	SeriesID  int64   `json:"series_id"`
	EpisodeID int64   `json:"episode_id"`
	LastPage  int     `json:"last_page"`
	Progress  float64 `json:"progress"`
}

// trackViewRequest is the JSON body for POST /track/view.
type trackViewRequest struct {
	SeriesID  int64 `json:"series_id"`
	EpisodeID int64 `json:"episode_id"`
}

// HandleTrackRead handles POST /track/read — buffers a reading progress event.
func (h *TrackerHandler) HandleTrackRead(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	// Authenticate
	userID, err := h.authenticate(r)
	if err != nil {
		http.Error(w, `{"error":"unauthorized"}`, http.StatusUnauthorized)
		return
	}

	// Parse body
	var req trackReadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"invalid JSON body"}`, http.StatusBadRequest)
		return
	}

	if req.SeriesID == 0 || req.EpisodeID == 0 {
		http.Error(w, `{"error":"series_id and episode_id are required"}`, http.StatusBadRequest)
		return
	}

	// Build event and push to Redis
	event := storage.ReadEvent{
		UserID:    userID,
		SeriesID:  req.SeriesID,
		EpisodeID: req.EpisodeID,
		LastPage:  req.LastPage,
		Progress:  req.Progress,
	}

	payload, _ := json.Marshal(event)
	if err := h.redis.Push(r.Context(), "tracking:reads", string(payload)); err != nil {
		log.Printf("[ERROR] Failed to push read event to Redis: %v", err)
		http.Error(w, `{"error":"internal server error"}`, http.StatusInternalServerError)
		return
	}

	log.Printf("[TRACK] Read: user=%d series=%d ep=%d page=%d progress=%.1f%%",
		userID, req.SeriesID, req.EpisodeID, req.LastPage, req.Progress)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusAccepted)
	fmt.Fprintf(w, `{"message":"tracked","queued":true}`)
}

// HandleTrackView handles POST /track/view — buffers a view event.
func (h *TrackerHandler) HandleTrackView(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	// Authenticate
	userID, err := h.authenticate(r)
	if err != nil {
		http.Error(w, `{"error":"unauthorized"}`, http.StatusUnauthorized)
		return
	}

	// Parse body
	var req trackViewRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, `{"error":"invalid JSON body"}`, http.StatusBadRequest)
		return
	}

	if req.SeriesID == 0 || req.EpisodeID == 0 {
		http.Error(w, `{"error":"series_id and episode_id are required"}`, http.StatusBadRequest)
		return
	}

	// Build event and push to Redis
	event := storage.ViewEvent{
		UserID:    userID,
		EpisodeID: req.EpisodeID,
		SeriesID:  req.SeriesID,
		ViewDate:  time.Now().Format("2006-01-02"),
	}

	payload, _ := json.Marshal(event)
	if err := h.redis.Push(r.Context(), "tracking:views", string(payload)); err != nil {
		log.Printf("[ERROR] Failed to push view event to Redis: %v", err)
		http.Error(w, `{"error":"internal server error"}`, http.StatusInternalServerError)
		return
	}

	log.Printf("[TRACK] View: user=%d series=%d ep=%d", userID, req.SeriesID, req.EpisodeID)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusAccepted)
	fmt.Fprintf(w, `{"message":"tracked","queued":true}`)
}

// authenticate extracts and validates the Bearer token from the request.
func (h *TrackerHandler) authenticate(r *http.Request) (int64, error) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
		return 0, fmt.Errorf("missing or invalid Authorization header")
	}

	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()

	return h.postgres.ValidateToken(ctx, authHeader)
}
