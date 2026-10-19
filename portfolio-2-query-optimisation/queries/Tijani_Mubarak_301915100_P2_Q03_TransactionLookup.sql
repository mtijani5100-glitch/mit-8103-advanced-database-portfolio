-- Transaction lookup by reference with counterparty and reversal details
SELECT
    t.transaction_ref,
    t.transaction_type,
    t.status,
    t.amount,
    t.currency,
    sa.account_number  AS source_account,
    sc.full_name       AS source_customer,
    da.account_number  AS destination_account,
    dc.full_name       AS destination_customer,
    t.initiated_by,
    t.failure_reason,
    t.created_at,
    t.posted_at,
    rev.transaction_ref AS reversed_by_ref
FROM transactions t
LEFT JOIN accounts sa   ON t.source_account_id      = sa.account_id
LEFT JOIN customers sc  ON sa.customer_id            = sc.customer_id
LEFT JOIN accounts da   ON t.destination_account_id  = da.account_id
LEFT JOIN customers dc  ON da.customer_id            = dc.customer_id
LEFT JOIN transactions rev ON rev.reversal_of_transaction_id = t.transaction_id
WHERE t.transaction_ref = 'TXN-2026-TRF-001';
