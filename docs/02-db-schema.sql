-- SQLite Database Schema for AI-Powered Stock Portfolio Tool
-- Note on Decimal/Financial Values: SQLite does not natively support DECIMAL/NUMERIC types with strict enforcement.
-- To prevent floating-point rounding errors (as required for financial applications), all monetary values
-- MUST be stored as INTEGERs representing cents (or the smallest denomination of the currency).
-- Fractional shares are similarly stored as INTEGERs scaled by 10,000 (e.g., 1.5 shares = 15000).

PRAGMA foreign_keys = ON;

CREATE TABLE users (
    id TEXT PRIMARY KEY, -- UUID
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    mfa_secret TEXT, -- Multi-factor authentication secret
    is_mfa_enabled BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE portfolio_holdings (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    symbol TEXT NOT NULL,
    -- Store quantity as integer * 10000 to handle fractional shares safely
    quantity_x10000 INTEGER NOT NULL, 
    -- Store currency values in cents
    average_price_cents INTEGER NOT NULL, 
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE watchlists (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    symbol TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE(user_id, symbol)
);

-- SOX-style Audit Trail
CREATE TABLE audit_logs (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    action TEXT NOT NULL, -- e.g., 'CREATE_HOLDING', 'UPDATE_HOLDING', 'DELETE_HOLDING'
    table_name TEXT NOT NULL,
    record_id TEXT NOT NULL,
    old_values TEXT, -- JSON serialization of old state
    new_values TEXT, -- JSON serialization of new state
    ip_address TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Idempotency Keys for exactly-once processing
CREATE TABLE idempotency_keys (
    idempotency_key TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    request_path TEXT NOT NULL,
    response_status INTEGER,
    response_body TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Indexes for performance
CREATE INDEX idx_portfolio_user ON portfolio_holdings(user_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_record ON audit_logs(record_id);
