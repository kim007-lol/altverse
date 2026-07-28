package admin

import (
	"encoding/json"
	"sync"

	"aureader/backend/helper"

	"github.com/gin-gonic/gin"
)

// platformSettings holds live config values modifiable from the admin panel.
// Values survive in-process only; add DB/Redis persistence when needed.
type platformSettings struct {
	MinWithdrawalIDR   int     `json:"min_withdrawal_idr"`
	PlatformFeePercent float64 `json:"platform_fee_percent"`
	MaxTipsPerDay      int     `json:"max_tips_per_day"`
	MaintenanceMode    bool    `json:"maintenance_mode"`
	CoinToIDRRate      float64 `json:"coin_to_idr_rate"`
}

var (
	settingsMu sync.RWMutex
	settings   = platformSettings{
		MinWithdrawalIDR:   50000,
		PlatformFeePercent: 30,
		MaxTipsPerDay:      20,
		MaintenanceMode:    false,
		CoinToIDRRate:      1500,
	}
)

type SettingsController struct{}

func NewSettingsController() *SettingsController { return &SettingsController{} }

// GetSettings returns the current platform settings.
func (h *SettingsController) GetSettings(c *gin.Context) {
	settingsMu.RLock()
	defer settingsMu.RUnlock()
	helper.OK(c, "Settings fetched", settings)
}

// UpdateSettings merges the provided fields into the running config.
func (h *SettingsController) UpdateSettings(c *gin.Context) {
	var body struct {
		Settings json.RawMessage `json:"settings" binding:"required"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		helper.UnprocessableEntity(c, err.Error())
		return
	}

	settingsMu.Lock()
	defer settingsMu.Unlock()

	// Merge: unmarshal current into map, then overlay incoming fields.
	current, _ := json.Marshal(settings)
	merged := make(map[string]any)
	_ = json.Unmarshal(current, &merged)

	incoming := make(map[string]any)
	if err := json.Unmarshal(body.Settings, &incoming); err != nil {
		helper.BadRequest(c, "invalid settings JSON", nil)
		return
	}
	for k, v := range incoming {
		merged[k] = v
	}

	// Re-decode merged map back into typed struct.
	mergedJSON, _ := json.Marshal(merged)
	_ = json.Unmarshal(mergedJSON, &settings)

	helper.OK(c, "Settings updated", settings)
}
