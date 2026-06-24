package models

import "time"

type Transaction struct {
	ID          uint64    `gorm:"primaryKey;autoIncrement"              json:"id"`
	UserID      uint64    `gorm:"not null;index"                        json:"user_id"`
	Type        string    `gorm:"type:trx_transaction_type;not null"    json:"type"`
	Coins       int       `gorm:"not null;default:0"                    json:"coins"`
	AmountIDR   float64   `gorm:"column:amount_idr;type:numeric(15,2);not null;default:0" json:"amount_idr"`
	ReferenceID *string   `gorm:"type:varchar(255)"                     json:"reference_id"`
	Description *string   `gorm:"type:text"                             json:"description"`
	CreatedAt   time.Time `gorm:"autoCreateTime"                        json:"created_at"`

	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

func (Transaction) TableName() string { return "trx_transactions" }

type TopUp struct {
	ID                     uint64     `gorm:"primaryKey;autoIncrement"               json:"id"`
	UserID                 uint64     `gorm:"not null;index"                         json:"user_id"`
	CoinsRequested         int        `gorm:"not null"                               json:"coins_requested"`
	AmountIDR              float64    `gorm:"column:amount_idr;type:numeric(15,2);not null" json:"amount_idr"`
	MidtransOrderID        string     `gorm:"type:varchar(255);not null;uniqueIndex" json:"midtrans_order_id"`
	MidtransTransactionID  *string    `gorm:"type:varchar(255);uniqueIndex"          json:"midtrans_transaction_id"`
	PaymentURL             *string    `gorm:"type:text"                              json:"payment_url"`
	Status                 string     `gorm:"type:trx_status;not null;default:pending" json:"status"`
	PaidAt                 *time.Time `                                              json:"paid_at"`
	CreatedAt              time.Time  `gorm:"autoCreateTime"                         json:"created_at"`
	UpdatedAt              time.Time  `gorm:"autoUpdateTime"                         json:"updated_at"`

	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

func (TopUp) TableName() string { return "trx_top_ups" }

type Withdrawal struct {
	ID            uint64     `gorm:"primaryKey;autoIncrement"               json:"id"`
	UserID        uint64     `gorm:"not null;index"                         json:"user_id"`
	AmountIDR     float64    `gorm:"column:amount_idr;type:numeric(15,2);not null" json:"amount_idr"`
	BankName      string     `gorm:"type:varchar(100);not null"             json:"bank_name"`
	AccountNumber string     `gorm:"type:varchar(100);not null"             json:"account_number"`
	AccountName   string     `gorm:"type:varchar(255);not null"             json:"account_name"`
	Status        string     `gorm:"type:trx_status;not null;default:pending" json:"status"`
	Notes         *string    `gorm:"type:text"                              json:"notes"`
	ProcessedAt   *time.Time `                                              json:"processed_at"`
	CreatedAt     time.Time  `gorm:"autoCreateTime"                         json:"created_at"`
	UpdatedAt     time.Time  `gorm:"autoUpdateTime"                         json:"updated_at"`

	User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

func (Withdrawal) TableName() string { return "trx_withdrawals" }

// EpisodeUnlock records a reader's coin purchase of a premium episode.
// The (UserID, EpisodeID) pair is unique so a reader can only buy an episode once.
type EpisodeUnlock struct {
	ID         uint64    `gorm:"primaryKey;autoIncrement"        json:"id"`
	UserID     uint64    `gorm:"not null;uniqueIndex:uidx_unlock" json:"user_id"`
	EpisodeID  uint64    `gorm:"not null;uniqueIndex:uidx_unlock" json:"episode_id"`
	CoinsSpent int       `gorm:"not null;default:0"              json:"coins_spent"`
	CreatedAt  time.Time `gorm:"autoCreateTime"                  json:"created_at"`

	Episode Episode `gorm:"foreignKey:EpisodeID" json:"episode,omitempty"`
}

func (EpisodeUnlock) TableName() string { return "trx_episode_unlocks" }
