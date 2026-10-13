-- Portfolio 2: Query Processing and Optimisation
-- Q07 — Balance reconciliation: cached vs ledger-derived
-- Demonstrates: LEFT JOIN aggregate, COALESCE, mismatch detection

SELECT
    a.account_number,
    c.full_name,
    a.available_balance                       AS cached_balance,
    COALESCE(
        SUM(CASE
            WHEN le.entry_side = 'CREDIT' THEN  le.amount
            WHEN le.entry_side = 'DEBIT'  THEN -le.amount
        END), 0
    )                                         AS ledger_derived_balance,
    a.available_balance - COALESCE(
        SUM(CASE
            WHEN le.entry_side = 'CREDIT' THEN  le.amount
            WHEN le.entry_side = 'DEBIT'  THEN -le.amount
        END), 0
    )                                         AS discrepancy
FROM accounts a
JOIN customers c ON a.customer_id = c.customer_id
LEFT JOIN ledger_entries le ON le.account_id = a.account_id
WHERE a.account_kind = 'CUSTOMER'
GROUP BY a.account_id, a.account_number, c.full_name, a.available_balance
HAVING a.available_balance <> COALESCE(
    SUM(CASE
        WHEN le.entry_side = 'CREDIT' THEN  le.amount
        WHEN le.entry_side = 'DEBIT'  THEN -le.amount
    END), 0
)
ORDER BY ABS(a.available_balance - COALESCE(
    SUM(CASE
        WHEN le.entry_side = 'CREDIT' THEN  le.amount
        WHEN le.entry_side = 'DEBIT'  THEN -le.amount
    END), 0
)) DESC;

-- Variant: show ALL accounts including those with zero discrepancy
-- (remove the HAVING clause for a full report)
