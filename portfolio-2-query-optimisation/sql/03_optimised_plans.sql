-- Portfolio 2: Query Processing and Optimisation
-- Capture optimised EXPLAIN ANALYZE plans AFTER adding 02_create_indexes.sql
-- Identical queries to 01_baseline_plans.sql for direct comparison

\echo '=========================================='
\echo 'OPTIMISED PLAN CAPTURE — Portfolio 2'
\echo 'Run AFTER 02_create_indexes.sql'
\echo '=========================================='

\echo ''
\echo '--- Environment ---'
SELECT version();
SELECT COUNT(*) AS customer_count FROM customers;
SELECT COUNT(*) AS account_count FROM accounts;
SELECT COUNT(*) AS transaction_count FROM transactions;
SELECT COUNT(*) AS ledger_entry_count FROM ledger_entries;

ANALYZE customers;
ANALYZE accounts;
ANALYZE transactions;
ANALYZE ledger_entries;

\echo ''
\echo '=== Q01: Customer Accounts ==='
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT a.account_number, a.account_kind, a.account_type, a.currency,
       a.available_balance, a.status, a.created_at
FROM accounts a
JOIN customers c ON a.customer_id = c.customer_id
WHERE c.full_name = 'Amaka Okonkwo'
ORDER BY a.account_number;

\echo ''
\echo '=== Q02: Account Transaction History (paginated) ==='
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT t.transaction_ref, t.transaction_type, t.status, t.amount, t.currency,
       sa.account_number AS source_account, da.account_number AS destination_account,
       t.initiated_by, t.created_at, t.posted_at
FROM transactions t
LEFT JOIN accounts sa ON t.source_account_id = sa.account_id
LEFT JOIN accounts da ON t.destination_account_id = da.account_id
WHERE t.source_account_id = (SELECT account_id FROM accounts WHERE account_number = '1000000001')
   OR t.destination_account_id = (SELECT account_id FROM accounts WHERE account_number = '1000000001')
ORDER BY t.created_at DESC
LIMIT 10 OFFSET 0;

\echo ''
\echo '=== Q03: Transaction Lookup by Reference ==='
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT t.transaction_ref, t.transaction_type, t.status, t.amount, t.currency,
       sa.account_number AS source_account, sc.full_name AS source_customer,
       da.account_number AS destination_account, dc.full_name AS destination_customer,
       t.initiated_by, t.failure_reason, t.created_at, t.posted_at,
       rev.transaction_ref AS reversed_by_ref
FROM transactions t
LEFT JOIN accounts sa   ON t.source_account_id      = sa.account_id
LEFT JOIN customers sc  ON sa.customer_id            = sc.customer_id
LEFT JOIN accounts da   ON t.destination_account_id  = da.account_id
LEFT JOIN customers dc  ON da.customer_id            = dc.customer_id
LEFT JOIN transactions rev ON rev.reversal_of_transaction_id = t.transaction_id
WHERE t.transaction_ref = 'TXN-2026-TRF-001';

\echo ''
\echo '=== Q04: Pending/Failed Operations ==='
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT t.transaction_ref, t.transaction_type, t.status, t.amount, t.currency,
       sa.account_number AS source_account, da.account_number AS destination_account,
       t.initiated_by, t.failure_reason, t.created_at
FROM transactions t
LEFT JOIN accounts sa ON t.source_account_id      = sa.account_id
LEFT JOIN accounts da ON t.destination_account_id  = da.account_id
WHERE t.status IN ('PENDING', 'FAILED')
  AND t.created_at >= NOW() - INTERVAL '30 days'
ORDER BY t.created_at DESC;

\echo ''
\echo '=== Q05: Daily Transaction Totals ==='
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT DATE_TRUNC('day', t.created_at)::DATE AS tx_date, t.transaction_type, t.status,
       COUNT(*) AS tx_count, SUM(t.amount) AS total_amount,
       MIN(t.amount) AS min_amount, MAX(t.amount) AS max_amount
FROM transactions t
WHERE t.created_at >= NOW() - INTERVAL '90 days'
GROUP BY tx_date, t.transaction_type, t.status
ORDER BY tx_date DESC, t.transaction_type, t.status;

\echo ''
\echo '=== Q06: High-Value Transfers ==='
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT t.transaction_ref, t.amount, t.status,
       sa.account_number AS source_account, sc.full_name AS source_customer,
       da.account_number AS destination_account, dc.full_name AS destination_customer,
       t.created_at, t.posted_at
FROM transactions t
JOIN accounts sa  ON t.source_account_id      = sa.account_id
JOIN customers sc ON sa.customer_id            = sc.customer_id
JOIN accounts da  ON t.destination_account_id  = da.account_id
LEFT JOIN customers dc ON da.customer_id       = dc.customer_id
WHERE t.transaction_type = 'TRANSFER'
  AND t.amount >= 50000.00
ORDER BY t.amount DESC, t.created_at DESC;

\echo ''
\echo '=== Q07: Balance Reconciliation ==='
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT a.account_number, c.full_name,
       a.available_balance AS cached_balance,
       COALESCE(SUM(CASE WHEN le.entry_side = 'CREDIT' THEN le.amount
                         WHEN le.entry_side = 'DEBIT'  THEN -le.amount END), 0) AS ledger_derived,
       a.available_balance - COALESCE(
           SUM(CASE WHEN le.entry_side = 'CREDIT' THEN le.amount
                    WHEN le.entry_side = 'DEBIT'  THEN -le.amount END), 0) AS discrepancy
FROM accounts a
JOIN customers c ON a.customer_id = c.customer_id
LEFT JOIN ledger_entries le ON le.account_id = a.account_id
WHERE a.account_kind = 'CUSTOMER'
GROUP BY a.account_id, a.account_number, c.full_name, a.available_balance
ORDER BY a.account_number;

\echo ''
\echo '=== Q08: Unbalanced Journals ==='
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT t.transaction_id, t.transaction_ref, t.transaction_type, t.amount AS expected_amount,
       COUNT(le.entry_id) AS entry_count,
       COALESCE(SUM(CASE WHEN le.entry_side = 'DEBIT'  THEN le.amount END), 0) AS total_debits,
       COALESCE(SUM(CASE WHEN le.entry_side = 'CREDIT' THEN le.amount END), 0) AS total_credits
FROM transactions t
LEFT JOIN ledger_entries le ON le.transaction_id = t.transaction_id
WHERE t.status = 'POSTED'
GROUP BY t.transaction_id, t.transaction_ref, t.transaction_type, t.amount
HAVING COUNT(le.entry_id) = 0
    OR SUM(CASE WHEN le.entry_side = 'DEBIT'  THEN le.amount END) <>
       SUM(CASE WHEN le.entry_side = 'CREDIT' THEN le.amount END)
ORDER BY t.transaction_ref;

\echo ''
\echo '=== Q09: Net Movement (reversal-adjusted) ==='
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
WITH posted_transactions AS (
    SELECT t.transaction_id, t.transaction_type, t.amount, t.created_at,
           CASE WHEN rev.transaction_id IS NOT NULL THEN TRUE ELSE FALSE END AS is_reversed
    FROM transactions t
    LEFT JOIN transactions rev ON rev.reversal_of_transaction_id = t.transaction_id
    WHERE t.status = 'POSTED' AND t.created_at >= NOW() - INTERVAL '90 days'
)
SELECT
    SUM(CASE WHEN transaction_type IN ('TRANSFER','DEPOSIT','WITHDRAWAL') THEN amount ELSE 0 END) AS gross_movement,
    SUM(CASE WHEN transaction_type = 'REVERSAL' THEN amount ELSE 0 END) AS reversal_total,
    SUM(CASE WHEN transaction_type <> 'REVERSAL' AND is_reversed THEN amount ELSE 0 END) AS reversed_original_total,
    SUM(CASE WHEN transaction_type IN ('TRANSFER','DEPOSIT','WITHDRAWAL') AND NOT is_reversed THEN amount ELSE 0 END) AS net_movement,
    COUNT(*) AS total_posted
FROM posted_transactions;

\echo ''
\echo '=== Q10: Full Join Report ==='
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
WITH ledger_summary AS (
    SELECT le.transaction_id, le.account_id,
           SUM(CASE WHEN le.entry_side = 'DEBIT'  THEN le.amount ELSE 0 END) AS debit_total,
           SUM(CASE WHEN le.entry_side = 'CREDIT' THEN le.amount ELSE 0 END) AS credit_total,
           COUNT(*) AS entry_count
    FROM ledger_entries le GROUP BY le.transaction_id, le.account_id
)
SELECT c.full_name, c.status AS customer_status, a.account_number, a.account_type,
       a.available_balance, t.transaction_ref, t.transaction_type, t.status AS tx_status,
       t.amount AS tx_amount, ls.debit_total, ls.credit_total, ls.entry_count,
       t.created_at AS tx_date
FROM customers c
JOIN accounts a ON a.customer_id = c.customer_id
JOIN transactions t ON (t.source_account_id = a.account_id OR t.destination_account_id = a.account_id)
LEFT JOIN ledger_summary ls ON ls.transaction_id = t.transaction_id AND ls.account_id = a.account_id
WHERE c.full_name = 'Amaka Okonkwo'
ORDER BY a.account_number, t.created_at DESC;

\echo ''
\echo '=========================================='
\echo 'OPTIMISED CAPTURE COMPLETE'
\echo '=========================================='
