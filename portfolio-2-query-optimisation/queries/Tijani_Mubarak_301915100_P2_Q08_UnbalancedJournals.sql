-- Integrity audit: flags posted transactions with missing or unbalanced debit/credit entries
SELECT
    t.transaction_id,
    t.transaction_ref,
    t.transaction_type,
    t.amount                                  AS expected_amount,
    COUNT(le.entry_id)                        AS entry_count,
    COALESCE(SUM(CASE WHEN le.entry_side = 'DEBIT'  THEN le.amount END), 0)
                                              AS total_debits,
    COALESCE(SUM(CASE WHEN le.entry_side = 'CREDIT' THEN le.amount END), 0)
                                              AS total_credits,
    CASE
        WHEN COUNT(le.entry_id) = 0 THEN 'MISSING JOURNAL'
        WHEN SUM(CASE WHEN le.entry_side = 'DEBIT'  THEN le.amount END) <>
             SUM(CASE WHEN le.entry_side = 'CREDIT' THEN le.amount END)
             THEN 'UNBALANCED'
        ELSE 'OK'
    END                                       AS integrity_status
FROM transactions t
LEFT JOIN ledger_entries le ON le.transaction_id = t.transaction_id
WHERE t.status = 'POSTED'
GROUP BY t.transaction_id, t.transaction_ref, t.transaction_type, t.amount
HAVING COUNT(le.entry_id) = 0
    OR SUM(CASE WHEN le.entry_side = 'DEBIT'  THEN le.amount END) <>
       SUM(CASE WHEN le.entry_side = 'CREDIT' THEN le.amount END)
ORDER BY t.transaction_ref;
