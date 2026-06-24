package reader

import (
	"strconv"

	"aureader/backend/controllers"
	"aureader/backend/dto"
	"aureader/backend/helper"
	"aureader/backend/middleware"
	"aureader/backend/services"

	"github.com/gin-gonic/gin"
)

type NotificationController struct {
	notifSvc services.NotificationService
}

func NewNotificationController(notifSvc services.NotificationService) *NotificationController {
	return &NotificationController{notifSvc: notifSvc}
}

// List returns the user's notifications (paginated) plus the unread count.
func (h *NotificationController) List(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	page, perPage := controllers.PaginationParams(c)
	items, unread, total, err := h.notifSvc.List(userID, page, perPage)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Notifications fetched", gin.H{
		"data":         items,
		"unread_count": unread,
		"total":        total,
		"page":         page,
		"per_page":     perPage,
	})
}

func (h *NotificationController) UnreadCount(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	count, err := h.notifSvc.UnreadCount(userID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Unread count fetched", gin.H{"unread_count": count})
}

func (h *NotificationController) MarkRead(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		helper.BadRequest(c, "invalid notification id", nil)
		return
	}
	userID := uint64(middleware.GetUserID(c))
	if err := h.notifSvc.MarkRead(id, userID); err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.NoContent(c, "Notification marked as read")
}

func (h *NotificationController) MarkAllRead(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	if err := h.notifSvc.MarkAllRead(userID); err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.NoContent(c, "All notifications marked as read")
}

func (h *NotificationController) GetPreferences(c *gin.Context) {
	userID := uint64(middleware.GetUserID(c))
	prefs, err := h.notifSvc.GetPreferences(userID)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Preferences fetched", gin.H{"preferences": prefs})
}

func (h *NotificationController) UpdatePreferences(c *gin.Context) {
	var req dto.UpdatePreferencesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	updates := make([]services.PreferenceUpdate, 0, len(req.Preferences))
	for _, p := range req.Preferences {
		u := services.PreferenceUpdate{
			Type:    p.Type,
			Enabled: *p.Enabled,
			// Default the optional channels to the master toggle when omitted.
			PushEnabled:  *p.Enabled,
			EmailEnabled: false,
		}
		if p.PushEnabled != nil {
			u.PushEnabled = *p.PushEnabled
		}
		if p.EmailEnabled != nil {
			u.EmailEnabled = *p.EmailEnabled
		}
		updates = append(updates, u)
	}

	userID := uint64(middleware.GetUserID(c))
	if err := h.notifSvc.UpdatePreferences(userID, updates); err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Preferences updated", nil)
}

func (h *NotificationController) Cleanup(c *gin.Context) {
	var req dto.CleanupRequest
	_ = c.ShouldBindJSON(&req) // body optional; days defaults in the service
	userID := uint64(middleware.GetUserID(c))
	deleted, err := h.notifSvc.Cleanup(userID, req.Days)
	if err != nil {
		controllers.HandleErr(c, err)
		return
	}
	helper.OK(c, "Notifications cleaned up", gin.H{"deleted_count": deleted})
}
