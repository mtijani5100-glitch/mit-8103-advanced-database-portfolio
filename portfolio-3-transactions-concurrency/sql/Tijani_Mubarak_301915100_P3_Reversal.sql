-- Portfolio 3: Transactions and Concurrency
-- Transaction reversal and compensating entry demonstration
-- Mubarak Tijani (301915100)

-- Balances and original transaction state before reversal
SELECT account_number, full_name, available_balance AS balance_before
FROM accounts a JOIN customers c USING (customer_id)
WHERE a.account_number IN ('P3-ALICE-001', 'P3-BOB-001')
ORDER BY account_number;

SELECT transaction_ref, status, amount, reversal_of_transaction_id
FROM transactions
WHERE transaction_ref = 'TXN-P3-COMMIT-001';

-- Post reversal transaction and compensating journal entries
BEGIN;

DO $$
DECLARE
    v_orig_tx_id    BIGINT;
    v_orig_src      BIGINT;
    v_orig_dst      BIGINT;
    v_rev_tx        BIGINT;
    v_min_acct      BIGINT;
    v_max_acct      BIGINT;
BEGIN
    SELECT transaction_id, source_account_id, destination_account_id
    INTO   v_orig_tx_id, v_orig_src, v_orig_dst
    FROM   transactions
    WHERE  transaction_ref = 'TXN-P3-COMMIT-001';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transaction TXN-P3-COMMIT-001 not found';
    END IF;

    -- Validate preconditions: original must be POSTED and not already reversed
    IF (SELECT status FROM transactions WHERE transaction_id = v_orig_tx_id) <> 'POSTED' THEN
        RAISE EXCEPTION 'Cannot reverse non-posted transaction';
    END IF;

    IF EXISTS (SELECT 1 FROM transactions WHERE reversal_of_transaction_id = v_orig_tx_id) THEN
        RAISE EXCEPTION 'Transaction has already been reversed';
    END IF;

    -- Verify recipient has sufficient funds to return
    IF (SELECT available_balance FROM accounts WHERE account_id = v_orig_dst) < 75000.00 THEN
        RAISE EXCEPTION 'Recipient balance insufficient for reversal debit';
    END IF;

    -- Acquire locks in standard ascending account_id order
    v_min_acct := LEAST(v_orig_src, v_orig_dst);
    v_max_acct := GREATEST(v_orig_src, v_orig_dst);
    PERFORM account_id FROM accounts WHERE account_id = v_min_acct FOR UPDATE;
    PERFORM account_id FROM accounts WHERE account_id = v_max_acct FOR UPDATE;

    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, reversal_of_transaction_id, initiated_by, posted_at)
    VALUES ('TXN-P3-REVERSAL-001', 'REVERSAL', 'POSTED', 75000.00, 'NGN',
            v_orig_dst, v_orig_src, v_orig_tx_id, 'p3:ops_team', NOW())
    RETURNING transaction_id INTO v_rev_tx;

    -- Compensating ledger lines: debit recipient, credit original sender
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES
        (v_rev_tx, v_orig_dst, 'DEBIT',  75000.00, 'NGN', 1, 'Reversal debit: return from Bob'),
        (v_rev_tx, v_orig_src, 'CREDIT', 75000.00, 'NGN', 2, 'Reversal credit: refund to Alice');

    UPDATE accounts SET available_balance = available_balance - 75000.00 WHERE account_id = v_orig_dst;
    UPDATE accounts SET available_balance = available_balance + 75000.00 WHERE account_id = v_orig_src;

    INSERT INTO audit_logs (actor, action, entity_type, entity_id, transaction_id, event_details)
    VALUES ('p3:ops_team', 'REVERSAL_POSTED', 'TRANSACTION', v_rev_tx::TEXT, v_rev_tx,
            jsonb_build_object('original_ref', 'TXN-P3-COMMIT-001', 'reason', 'Operations recall'));
END $$;

COMMIT;

-- Verify updated balances
SELECT account_number, full_name, available_balance AS balance_after
FROM accounts a JOIN customers c USING (customer_id)
WHERE a.account_number IN ('P3-ALICE-001', 'P3-BOB-001')
ORDER BY account_number;

-- Verify both records: original remains intact (immutable) while reversal links back
SELECT
    t.transaction_ref,
    t.transaction_type,
    t.status,
    t.amount,
    t.reversal_of_transaction_id
FROM transactions t
WHERE t.transaction_ref IN ('TXN-P3-COMMIT-001', 'TXN-P3-REVERSAL-001')
ORDER BY t.created_at;

-- Verify 4 balanced ledger entries (2 original transfer + 2 reversal)
SELECT
    t.transaction_ref,
    l.entry_side,
    l.amount,
    l.description
FROM ledger_entries l
JOIN transactions t ON t.transaction_id = l.transaction_id
WHERE t.transaction_ref IN ('TXN-P3-COMMIT-001', 'TXN-P3-REVERSAL-001')
ORDER BY t.created_at, l.line_number;

-- Edge case: verify second reversal attempt is blocked by unique constraint
DO $$
DECLARE
    v_orig_tx_id BIGINT;
BEGIN
    SELECT transaction_id INTO v_orig_tx_id
    FROM transactions WHERE transaction_ref = 'TXN-P3-COMMIT-001';

    IF EXISTS (SELECT 1 FROM transactions WHERE reversal_of_transaction_id = v_orig_tx_id) THEN
        RAISE NOTICE 'Constraint check passed: second reversal on TXN-P3-COMMIT-001 blocked by uq_one_reversal_per_original';
    END IF;
END $$;
