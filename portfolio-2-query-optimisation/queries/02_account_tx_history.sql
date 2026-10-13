-- Portfolio 2: Query Processing and Optimisation
-- Q02 — Transaction history for one account, newest first, with pagination
-- Demonstrates: composite index usage, LIMIT/OFFSET pagination

SELECT
    t.transaction_ref,
    t.transaction_type,
    t.status,
    t.amount,
    t.currency,
    sa.account_number  AS source_account,
    da.account_number  AS destination_account,
    t.initiated_by,
    t.created_at,
    t.posted_at
FROM transactions t
LEFT JOIN accounts sa ON t.source_account_id = sa.account_id
LEFT JOIN accounts da ON t.destination_account_id = da.account_id
WHERE t.source_account_id = (
    SELECT account_id FROM accounts WHERE account_number = '1000000001'
)
   OR t.destination_account_id = (
    SELECT account_id FROM accounts WHERE account_number = '1000000001'
)
ORDER BY t.created_at DESC
LIMIT 10 OFFSET 0;
