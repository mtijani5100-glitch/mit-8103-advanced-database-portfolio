-- Portfolio 2: Query Processing and Optimisation
-- Q05 — Daily transaction totals grouped by type and status
-- Demonstrates: DATE_TRUNC, GROUP BY, aggregate functions

SELECT
    DATE_TRUNC('day', t.created_at)::DATE AS tx_date,
    t.transaction_type,
    t.status,
    COUNT(*)                              AS tx_count,
    SUM(t.amount)                         AS total_amount,
    MIN(t.amount)                         AS min_amount,
    MAX(t.amount)                         AS max_amount
FROM transactions t
WHERE t.created_at >= NOW() - INTERVAL '90 days'
GROUP BY tx_date, t.transaction_type, t.status
ORDER BY tx_date DESC, t.transaction_type, t.status;
