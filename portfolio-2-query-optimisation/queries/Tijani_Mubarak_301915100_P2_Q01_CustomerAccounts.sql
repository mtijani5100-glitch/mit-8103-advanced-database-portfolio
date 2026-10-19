-- Retrieve all accounts for a customer
SELECT
    a.account_number,
    a.account_kind,
    a.account_type,
    a.currency,
    a.available_balance,
    a.status,
    a.created_at
FROM accounts a
JOIN customers c ON a.customer_id = c.customer_id
WHERE c.full_name = 'Amaka Okonkwo'
ORDER BY a.account_number;
