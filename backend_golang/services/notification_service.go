package services

import (
	"context"
	"encoding/json"
	"log"
	"time"

	"aureader/backend/errorhandler"
	"aureader/backend/models"
	"aureader/backend/repositories"

	"github.com/redis/go-redis/v9"
)

// notificationTypeDefault describes a notification type plus its human label,
// used to render the preferences screen even before a user has saved anything.
type notificationTypeDefault struct {
	Type        string `json:"type"`
	Description string `json:"description"`
}

// DefaultNotificationTypes is the catalog of notification types the app knows about.
// Descriptions are in Indonesian to match the app's locale.
var DefaultNotificationTypes = []notificationTypeDefault{
	{"new_follower", "Seseorang mulai mengikuti kamu"},
	{"new_comment", "Komentar baru di episode kamu"},
	{"comment_reply", "Balasan untuk komentar kamu"},
	{"comment_like", "Seseorang menyukai komentar kamu"},
	{"episode_like", "Seseorang menyukai episode kamu"},
	{"series_like", "Seseorang menyukai serial kamu"},
	{"new_episode", "Episode baru dari penulis yang kamu ikuti"},
	{"episode_unlock", "Episode kamu di-unlock oleh pembaca"},
	{"tip_received", "Kamu menerima tip koin"},
	{"mission_complete", "Misi berhasil diselesaikan"},
	{"badge_earned", "Kamu memperoleh badge baru"},
	{"level_up", "Kamu naik level"},
	{"daily_reward", "Hadiah harian tersedia untuk diklaim"},
}

// CreateNotificationInput is what other services pass to raise a notification.
type CreateNotificationInput struct {
	UserID uint64
	Type   string
	Title  string
	Body   string
	Data   map[string]any
}

// PreferenceView is the merged (defaults + stored) preference entry returned to the client.
type PreferenceView struct {
	Type         string `json:"type"`
	Description  string `json:"description"`
	Enabled      bool   `json:"enabled"`
	PushEnabled  bool   `json:"push_enabled"`
	EmailEnabled bool   `json:"email_enabled"`
}

// PreferenceUpdate is a single preference change coming from the client.
type PreferenceUpdate struct {
	Type         string
	Enabled      bool
	PushEnabled  bool
	EmailEnabled bool
}

type NotificationService interface {
	Create(input CreateNotificationInput) (*models.Notification, error)
	List(userID uint64, page, perPage int) (items []models.Notification, unread int64, total int64, err error)
	UnreadCount(userID uint64) (int64, error)
	MarkRead(id, userID uint64) error
	MarkAllRead(userID uint64) error
	GetPreferences(userID uint64) ([]PreferenceView, error)
	UpdatePreferences(userID uint64, updates []PreferenceUpdate) error
	Cleanup(userID uint64, days int) (int64, error)
}

type notificationService struct {
	repo repositories.NotificationRepository
	rdb  *redis.Client
}

func NewNotificationService(repo repositories.NotificationRepository, rdb *redis.Client) NotificationService {
	return &notificationService{repo: repo, rdb: rdb}
}

// Create persists a notification and publishes it to the Redis "notifications"
// channel so the WebSocket hub can push it to the connected user in realtime.
func (s *notificationService) Create(input CreateNotificationInput) (*models.Notification, error) {
	var raw json.RawMessage
	if input.Data != nil {
		if b, err := json.Marshal(input.Data); err == nil {
			raw = b
		}
	}

	n := &models.Notification{
		UserID: input.UserID,
		Type:   input.Type,
		Title:  input.Title,
		Body:   input.Body,
		Data:   raw,
	}
	if err := s.repo.Create(n); err != nil {
		return nil, errorhandler.NewInternalError("failed to create notification")
	}

	s.publish(n)
	return n, nil
}

// publish is best-effort: a realtime delivery failure must not fail the write.
func (s *notificationService) publish(n *models.Notification) {
	if s.rdb == nil {
		return
	}
	payload := map[string]any{
		"id":         n.ID,
		"user_id":    n.UserID,
		"type":       n.Type,
		"title":      n.Title,
		"body":       n.Body,
		"data":       n.Data,
		"is_read":    n.IsRead,
		"created_at": n.CreatedAt,
	}
	b, err := json.Marshal(payload)
	if err != nil {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	if err := s.rdb.Publish(ctx, "notifications", b).Err(); err != nil {
		log.Printf("[NOTIF] publish failed for user %d: %v", n.UserID, err)
	}
}

func (s *notificationService) List(userID uint64, page, perPage int) ([]models.Notification, int64, int64, error) {
	items, total, err := s.repo.ListByUser(userID, page, perPage)
	if err != nil {
		return nil, 0, 0, errorhandler.NewInternalError("failed to fetch notifications")
	}
	unread, err := s.repo.CountUnread(userID)
	if err != nil {
		return nil, 0, 0, errorhandler.NewInternalError("failed to count unread")
	}
	return items, unread, total, nil
}

func (s *notificationService) UnreadCount(userID uint64) (int64, error) {
	count, err := s.repo.CountUnread(userID)
	if err != nil {
		return 0, errorhandler.NewInternalError("failed to count unread")
	}
	return count, nil
}

func (s *notificationService) MarkRead(id, userID uint64) error {
	affected, err := s.repo.MarkRead(id, userID)
	if err != nil {
		return errorhandler.NewInternalError("failed to mark notification read")
	}
	if affected == 0 {
		return errorhandler.NewNotFound("notification not found")
	}
	return nil
}

func (s *notificationService) MarkAllRead(userID uint64) error {
	if err := s.repo.MarkAllRead(userID); err != nil {
		return errorhandler.NewInternalError("failed to mark all read")
	}
	return nil
}

// GetPreferences returns every known type merged with the user's stored overrides,
// so the client always sees the full list with sensible defaults.
func (s *notificationService) GetPreferences(userID uint64) ([]PreferenceView, error) {
	stored, err := s.repo.ListPreferences(userID)
	if err != nil {
		return nil, errorhandler.NewInternalError("failed to fetch preferences")
	}
	byType := make(map[string]models.NotificationPreference, len(stored))
	for _, p := range stored {
		byType[p.NotificationType] = p
	}

	views := make([]PreferenceView, 0, len(DefaultNotificationTypes))
	for _, def := range DefaultNotificationTypes {
		view := PreferenceView{
			Type:         def.Type,
			Description:  def.Description,
			Enabled:      true,
			PushEnabled:  true,
			EmailEnabled: false,
		}
		if p, ok := byType[def.Type]; ok {
			view.Enabled = p.Enabled
			view.PushEnabled = p.PushEnabled
			view.EmailEnabled = p.EmailEnabled
		}
		views = append(views, view)
	}
	return views, nil
}

func (s *notificationService) UpdatePreferences(userID uint64, updates []PreferenceUpdate) error {
	for _, u := range updates {
		pref := &models.NotificationPreference{
			UserID:           userID,
			NotificationType: u.Type,
			Enabled:          u.Enabled,
			PushEnabled:      u.PushEnabled,
			EmailEnabled:     u.EmailEnabled,
		}
		if err := s.repo.UpsertPreference(pref); err != nil {
			return errorhandler.NewInternalError("failed to update preference")
		}
	}
	return nil
}

func (s *notificationService) Cleanup(userID uint64, days int) (int64, error) {
	if days <= 0 {
		days = 30
	}
	before := time.Now().AddDate(0, 0, -days)
	deleted, err := s.repo.DeleteReadOlderThan(userID, before)
	if err != nil {
		return 0, errorhandler.NewInternalError("failed to cleanup notifications")
	}
	return deleted, nil
}
