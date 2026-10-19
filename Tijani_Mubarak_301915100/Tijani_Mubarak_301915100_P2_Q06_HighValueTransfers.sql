-- AML threshold monitor: transfers exceeding 50,000 NGN
SELECT
    t.transaction_ref,
    t.amount,
    t.status,
    sa.account_number AS source_account,
    sc.full_name      AS source_customer,
    da.account_number AS destination_account,
    dc.full_name      AS destination_customer,
    t.created_at,
    t.posted_at
FROM transactions t
JOIN accounts sa  ON t.source_account_id      = sa.account_id
JOIN customers sc ON sa.customer_id            = sc.customer_id
JOIN accounts da  ON t.destination_account_id  = da.account_id
LEFT JOIN customers dc ON da.customer_id       = dc.customer_id
WHERE t.transaction_type = 'TRANSFER'
  AND t.amount >= 50000.00
ORDER BY t.amount DESC, t.created_at DESC;
