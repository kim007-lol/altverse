package dto

type TopUpRequest struct {
	CoinsPackage int `json:"coins_package" binding:"required,oneof=10 50 100 500 1000"`
}

type WithdrawalRequest struct {
	AmountIDR     float64 `json:"amount_idr"     binding:"required,min=50000"`
	BankName      string  `json:"bank_name"      binding:"required"`
	AccountNumber string  `json:"account_number" binding:"required"`
	AccountName   string  `json:"account_name"   binding:"required"`
}

type ProcessWithdrawalRequest struct {
	Approved bool   `json:"approved"`
	Notes    string `json:"notes"`
}
