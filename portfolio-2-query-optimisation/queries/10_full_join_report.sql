-- Portfolio 2: Query Processing and Optimisation
-- Q10 — Full report: customer → account → transactions → ledger entries
-- Demonstrates: multi-table join without accidental row multiplication
-- Uses a CTE to pre-aggregate ledger totals per transaction to avoid the N×M join trap

WITH ledger_summary AS (
    SELECT
        le.transaction_id,
        le.account_id,
        SUM(CASE WHEN le.entry_side = 'DEBIT'  THEN le.amount ELSE 0 END) AS debit_total,
        SUM(CASE WHEN le.entry_side = 'CREDIT' THEN le.amount ELSE 0 END) AS credit_total,
        COUNT(*)                                                           AS entry_count
    FROM ledger_entries le
    GROUP BY le.transaction_id, le.account_id
)
SELECT
    c.full_name,
    c.status        AS customer_status,
    a.account_number,
    a.account_type,
    a.available_balance,
    t.transaction_ref,
    t.transaction_type,
    t.status        AS tx_status,
    t.amount        AS tx_amount,
    ls.debit_total,
    ls.credit_total,
    ls.entry_count,
    t.created_at    AS tx_date
FROM customers c
JOIN accounts a ON a.customer_id = c.customer_id
JOIN transactions t ON (
    t.source_account_id = a.account_id
    OR t.destination_account_id = a.account_id
)
LEFT JOIN ledger_summary ls ON ls.transaction_id = t.transaction_id
                            AND ls.account_id    = a.account_id
WHERE c.full_name = 'Amaka Okonkwo'
ORDER BY a.account_number, t.created_at DESC;
