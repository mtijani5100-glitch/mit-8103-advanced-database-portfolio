-- Operational monitor: pending and failed transactions in the last 30 days
SELECT
    t.transaction_ref,
    t.transaction_type,
    t.status,
    t.amount,
    t.currency,
    sa.account_number AS source_account,
    da.account_number AS destination_account,
    t.initiated_by,
    t.failure_reason,
    t.created_at
FROM transactions t
LEFT JOIN accounts sa ON t.source_account_id      = sa.account_id
LEFT JOIN accounts da ON t.destination_account_id  = da.account_id
WHERE t.status IN ('PENDING', 'FAILED')
  AND t.created_at >= NOW() - INTERVAL '30 days'
ORDER BY t.created_at DESC;
