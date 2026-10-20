-- Performance indexes for analytical and operational query workloads

-- Partial composite index for posted transaction volume and high-value transfer lookups
CREATE INDEX IF NOT EXISTS idx_tx_type_amount
    ON transactions (transaction_type, amount DESC)
    WHERE status = 'POSTED';

-- Composite index to accelerate per-account debit/credit ledger aggregations
CREATE INDEX IF NOT EXISTS idx_ledger_account_side
    ON ledger_entries (account_id, entry_side);

-- Index to support bidirectional account transaction lookups
CREATE INDEX IF NOT EXISTS idx_tx_dest_account
    ON transactions (destination_account_id)
    WHERE destination_account_id IS NOT NULL;

ANALYZE transactions;
ANALYZE ledger_entries;

