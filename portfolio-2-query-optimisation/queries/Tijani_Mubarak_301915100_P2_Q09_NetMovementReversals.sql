-- Net volume report: excludes reversed originals and reversal entries to prevent double-counting
WITH posted_transactions AS (
    SELECT
        t.transaction_id,
        t.transaction_type,
        t.amount,
        t.created_at,
        CASE WHEN rev.transaction_id IS NOT NULL THEN TRUE ELSE FALSE END AS is_reversed
    FROM transactions t
    LEFT JOIN transactions rev ON rev.reversal_of_transaction_id = t.transaction_id
    WHERE t.status = 'POSTED'
      AND t.created_at >= NOW() - INTERVAL '90 days'
)
SELECT
    SUM(CASE WHEN transaction_type IN ('TRANSFER', 'DEPOSIT', 'WITHDRAWAL')
             THEN amount ELSE 0 END)          AS gross_movement,

    SUM(CASE WHEN transaction_type = 'REVERSAL'
             THEN amount ELSE 0 END)          AS reversal_total,

    SUM(CASE WHEN transaction_type <> 'REVERSAL' AND is_reversed
             THEN amount ELSE 0 END)          AS reversed_original_total,

    SUM(CASE WHEN transaction_type IN ('TRANSFER', 'DEPOSIT', 'WITHDRAWAL')
                  AND NOT is_reversed
             THEN amount ELSE 0 END)          AS net_movement,

    COUNT(*) FILTER (WHERE transaction_type <> 'REVERSAL' AND NOT is_reversed)
                                              AS net_tx_count,
    COUNT(*) FILTER (WHERE transaction_type = 'REVERSAL')
                                              AS reversal_count,
    COUNT(*)                                  AS total_posted
FROM posted_transactions;
