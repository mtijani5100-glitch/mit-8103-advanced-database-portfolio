-- Daily transaction totals grouped by type and status
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
