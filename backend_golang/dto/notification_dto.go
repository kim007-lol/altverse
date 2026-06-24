package dto

// UpdatePreferencesRequest is the body for PUT notifications/preferences.
type UpdatePreferencesRequest struct {
	Preferences []PreferenceItem `json:"preferences" binding:"required,min=1,dive"`
}

type PreferenceItem struct {
	Type         string `json:"type"          binding:"required"`
	Enabled      *bool  `json:"enabled"       binding:"required"`
	PushEnabled  *bool  `json:"push_enabled"`
	EmailEnabled *bool  `json:"email_enabled"`
}

// CleanupRequest is the body for POST notifications/cleanup. Days defaults to 30.
type CleanupRequest struct {
	Days int `json:"days"`
}
