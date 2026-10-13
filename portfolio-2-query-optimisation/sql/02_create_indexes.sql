-- Portfolio 2: Query Processing and Optimisation
-- Additional indexes for query performance improvement
-- These supplement the operational indexes already created in 01_create_schema.sql

-- Index for Q05 (daily totals) and Q06 (high-value transfers): type + amount filter
CREATE INDEX IF NOT EXISTS idx_tx_type_amount
    ON transactions (transaction_type, amount DESC)
    WHERE status = 'POSTED';

-- Index for Q07 (balance reconciliation): ledger entries per account grouped by side
CREATE INDEX IF NOT EXISTS idx_ledger_account_side
    ON ledger_entries (account_id, entry_side);

-- Index for Q10 (full join report): destination-side lookup for OR-condition join
CREATE INDEX IF NOT EXISTS idx_tx_dest_account
    ON transactions (destination_account_id)
    WHERE destination_account_id IS NOT NULL;

-- Refresh planner statistics after index creation
ANALYZE transactions;
ANALYZE ledger_entries;

\echo 'Portfolio 2 optimisation indexes created.'
