package admin

import (
	"aureader/backend/helper"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type BroadcastController struct {
	db       *gorm.DB
	notifSvc services.NotificationService
}

func NewBroadcastController(db *gorm.DB, notifSvc services.NotificationService) *BroadcastController {
	return &BroadcastController{db: db, notifSvc: notifSvc}
}

// Send broadcasts an in-app notification to all users or a specific role segment.
// Body: {title, body, type?, target: "all"|"reader"|"author"}
func (h *BroadcastController) Send(c *gin.Context) {
	var req struct {
		Title  string `json:"title"  binding:"required"`
		Body   string `json:"body"   binding:"required"`
		Type   string `json:"type"`
		Target string `json:"target" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}
	if req.Type == "" {
		req.Type = "announcement"
	}

	// Collect target user IDs.
	var userIDs []uint64
	q := h.db.Table("usr_users").Select("id").Where("deleted_at IS NULL")
	if req.Target != "all" {
		q = q.Where("role = ?", req.Target)
	}
	q.Scan(&userIDs)

	if len(userIDs) == 0 {
		helper.OK(c, "No recipients found", gin.H{"sent": 0})
		return
	}

	// Fire notifications in background to avoid blocking the response.
	go func() {
		for _, uid := range userIDs {
			_, _ = h.notifSvc.Create(services.CreateNotificationInput{
				UserID: uid,
				Type:   req.Type,
				Title:  req.Title,
				Body:   req.Body,
			})
		}
	}()

	helper.OK(c, "Broadcast queued", gin.H{"queued": len(userIDs), "target": req.Target})
}
