-- Portfolio 3: Transactions and Concurrency
-- Insufficient funds and boundary check demonstrations
-- Mubarak Tijani (301915100)

-- Check Alice's balance prior to over-limit attempt
SELECT account_number, full_name, available_balance AS current_balance_ngn
FROM accounts a JOIN customers c USING (customer_id)
WHERE a.account_number = 'P3-ALICE-001';

-- Attempt transfer exceeding available funds (1,000,000 NGN)
-- Fails gracefully under row lock, logs FAILED audit record with zero balance modification
DO $$
DECLARE
    v_tx         BIGINT;
    v_alice      BIGINT;
    v_bob        BIGINT;
    v_balance    NUMERIC;
    v_amount     CONSTANT NUMERIC := 1000000.00;
    v_reason     TEXT;
BEGIN
    SELECT account_id INTO v_alice FROM accounts WHERE account_number = 'P3-ALICE-001';
    SELECT account_id INTO v_bob   FROM accounts WHERE account_number = 'P3-BOB-001';

    -- Lock both rows in consistent order
    PERFORM account_id FROM accounts WHERE account_id = LEAST(v_alice, v_bob)    FOR UPDATE;
    PERFORM account_id FROM accounts WHERE account_id = GREATEST(v_alice, v_bob) FOR UPDATE;

    SELECT available_balance INTO v_balance FROM accounts WHERE account_id = v_alice;

    -- Evaluate guard condition while holding exclusive lock
    IF v_balance < v_amount THEN
        v_reason := FORMAT('Insufficient funds: available NGN %s, requested NGN %s',
                           v_balance, v_amount);

        INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
            source_account_id, destination_account_id, initiated_by, failure_reason)
        VALUES ('TXN-P3-INSUF-001', 'TRANSFER', 'FAILED', v_amount, 'NGN',
                v_alice, v_bob, 'p3:alice', v_reason)
        RETURNING transaction_id INTO v_tx;

        INSERT INTO audit_logs (actor, action, entity_type, entity_id, transaction_id, event_details)
        VALUES ('p3:alice', 'TRANSFER_FAILED', 'TRANSACTION', v_tx::TEXT, v_tx,
                jsonb_build_object('reason', v_reason, 'attempted_ngn', v_amount, 'available_ngn', v_balance));

        RAISE NOTICE 'Transfer rejected: %', v_reason;
        RETURN;
    END IF;

    RAISE EXCEPTION 'Assertion failed: transfer should have been rejected';
END $$;

-- Verify Alice's balance remains untouched
SELECT account_number, full_name, available_balance AS balance_after_rejection
FROM accounts a JOIN customers c USING (customer_id)
WHERE a.account_number = 'P3-ALICE-001';

-- Inspect audit record of failed attempt
SELECT
    transaction_ref,
    status,
    amount                AS amount_ngn,
    failure_reason,
    created_at
FROM transactions
WHERE transaction_ref = 'TXN-P3-INSUF-001';

-- Confirm no ledger entries were created
SELECT COUNT(*) AS ledger_lines_written
FROM ledger_entries l
JOIN transactions t ON t.transaction_id = l.transaction_id
WHERE t.transaction_ref = 'TXN-P3-INSUF-001';

-- Boundary check (AMT-08): attempt transfer exceeding balance by exactly 1 NGN
DO $$
DECLARE
    v_tx      BIGINT;
    v_alice   BIGINT;
    v_bob     BIGINT;
    v_balance NUMERIC;
    v_amount  NUMERIC;
    v_reason  TEXT;
BEGIN
    SELECT account_id INTO v_alice FROM accounts WHERE account_number = 'P3-ALICE-001';
    SELECT account_id INTO v_bob   FROM accounts WHERE account_number = 'P3-BOB-001';

    PERFORM account_id FROM accounts WHERE account_id = LEAST(v_alice, v_bob)    FOR UPDATE;
    PERFORM account_id FROM accounts WHERE account_id = GREATEST(v_alice, v_bob) FOR UPDATE;

    SELECT available_balance INTO v_balance FROM accounts WHERE account_id = v_alice;

    v_amount := v_balance + 1.00;
    v_reason := FORMAT('Insufficient by NGN 1.00: available NGN %s, requested NGN %s',
                       v_balance, v_amount);

    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, failure_reason)
    VALUES ('TXN-P3-EDGECASE-01', 'TRANSFER', 'FAILED', v_amount, 'NGN',
            v_alice, v_bob, 'p3:alice', v_reason)
    RETURNING transaction_id INTO v_tx;

    RAISE NOTICE 'Boundary check AMT-08 rejected as expected: %', v_reason;
END $$;

SELECT transaction_ref, status, amount AS amount_ngn, failure_reason
FROM transactions
WHERE transaction_ref = 'TXN-P3-EDGECASE-01';
