CREATE TYPE trx_transaction_type  AS ENUM ('topup', 'purchase', 'withdrawal', 'refund', 'reward');
CREATE TYPE trx_status            AS ENUM ('pending', 'success', 'failed', 'cancelled');

-- Master ledger — every coin movement lands here
CREATE TABLE trx_transactions (
    id          BIGSERIAL             PRIMARY KEY,
    user_id     BIGINT                NOT NULL REFERENCES usr_users(id) ON DELETE RESTRICT,
    type        trx_transaction_type  NOT NULL,
    coins       INT                   NOT NULL DEFAULT 0,
    amount_idr  NUMERIC(15, 2)        NOT NULL DEFAULT 0,
    reference_id VARCHAR(255),
    description TEXT,
    created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trx_transactions_user_id ON trx_transactions (user_id);
CREATE INDEX idx_trx_transactions_type    ON trx_transactions (type);

-- Midtrans top-up orders
CREATE TABLE trx_top_ups (
    id                     BIGSERIAL      PRIMARY KEY,
    user_id                BIGINT         NOT NULL REFERENCES usr_users(id) ON DELETE RESTRICT,
    coins_requested        INT            NOT NULL,
    amount_idr             NUMERIC(15, 2) NOT NULL,
    midtrans_order_id      VARCHAR(255)   NOT NULL UNIQUE,
    midtrans_transaction_id VARCHAR(255)  UNIQUE,
    payment_url            TEXT,
    status                 trx_status     NOT NULL DEFAULT 'pending',
    paid_at                TIMESTAMP WITH TIME ZONE,
    created_at             TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trx_top_ups_user_id           ON trx_top_ups (user_id);
CREATE INDEX idx_trx_top_ups_midtrans_order_id ON trx_top_ups (midtrans_order_id);

-- Author withdrawal requests
CREATE TABLE trx_withdrawals (
    id             BIGSERIAL      PRIMARY KEY,
    user_id        BIGINT         NOT NULL REFERENCES usr_users(id) ON DELETE RESTRICT,
    amount_idr     NUMERIC(15, 2) NOT NULL,
    bank_name      VARCHAR(100)   NOT NULL,
    account_number VARCHAR(100)   NOT NULL,
    account_name   VARCHAR(255)   NOT NULL,
    status         trx_status     NOT NULL DEFAULT 'pending',
    notes          TEXT,
    processed_at   TIMESTAMP WITH TIME ZONE,
    created_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trx_withdrawals_user_id ON trx_withdrawals (user_id);
CREATE INDEX idx_trx_withdrawals_status  ON trx_withdrawals (status);
