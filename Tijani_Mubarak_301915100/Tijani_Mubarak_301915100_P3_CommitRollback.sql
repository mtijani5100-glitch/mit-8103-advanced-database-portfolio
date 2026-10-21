-- Portfolio 3: Transactions and Concurrency
-- Commit and rollback demonstrations
-- Mubarak Tijani (301915100)

-- 1. Successful commit: transfer 75,000 NGN from Alice to Bob
-- Check baseline balances
SELECT account_number, full_name, available_balance AS balance_before
FROM accounts a JOIN customers c USING (customer_id)
WHERE a.account_number IN ('P3-ALICE-001', 'P3-BOB-001')
ORDER BY account_number;

-- Execute atomic transfer
BEGIN;

DO $$
DECLARE
    v_tx    BIGINT;
    v_alice BIGINT;
    v_bob   BIGINT;
    v_min   BIGINT;
    v_max   BIGINT;
BEGIN
    SELECT account_id INTO v_alice FROM accounts WHERE account_number = 'P3-ALICE-001';
    SELECT account_id INTO v_bob   FROM accounts WHERE account_number = 'P3-BOB-001';

    -- Lock accounts in deterministic order (ascending account_id) to prevent deadlocks
    v_min := LEAST(v_alice, v_bob);
    v_max := GREATEST(v_alice, v_bob);

    PERFORM account_id FROM accounts WHERE account_id = v_min FOR UPDATE;
    PERFORM account_id FROM accounts WHERE account_id = v_max FOR UPDATE;

    -- Funds check under lock
    IF (SELECT available_balance FROM accounts WHERE account_id = v_alice) < 75000.00 THEN
        RAISE EXCEPTION 'Insufficient funds in sender account';
    END IF;

    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, posted_at)
    VALUES ('TXN-P3-COMMIT-001', 'TRANSFER', 'POSTED', 75000.00, 'NGN',
            v_alice, v_bob, 'p3:alice', NOW())
    RETURNING transaction_id INTO v_tx;

    -- Post double-entry ledger lines
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES
        (v_tx, v_alice, 'DEBIT',  75000.00, 'NGN', 1, 'Transfer out: Alice to Bob'),
        (v_tx, v_bob,   'CREDIT', 75000.00, 'NGN', 2, 'Transfer in: Alice to Bob');

    -- Synchronize cached balances
    UPDATE accounts SET available_balance = available_balance - 75000.00 WHERE account_id = v_alice;
    UPDATE accounts SET available_balance = available_balance + 75000.00 WHERE account_id = v_bob;

    INSERT INTO audit_logs (actor, action, entity_type, entity_id, transaction_id, event_details)
    VALUES ('p3:alice', 'TRANSFER_POSTED', 'TRANSACTION', v_tx::TEXT, v_tx,
            jsonb_build_object('amount_ngn', 75000.00, 'from', 'P3-ALICE-001', 'to', 'P3-BOB-001'));
END $$;

COMMIT;

-- Verify balances after commit
SELECT account_number, full_name,
       available_balance          AS balance_after,
       available_balance * 100    AS balance_after_kobo
FROM accounts a JOIN customers c USING (customer_id)
WHERE a.account_number IN ('P3-ALICE-001', 'P3-BOB-001')
ORDER BY account_number;

-- Verify balanced ledger journal (debit = credit)
SELECT
    t.transaction_ref,
    t.status,
    l.entry_side,
    l.amount,
    l.description
FROM transactions t
JOIN ledger_entries l ON l.transaction_id = t.transaction_id
WHERE t.transaction_ref = 'TXN-P3-COMMIT-001'
ORDER BY l.line_number;


-- 2. Deliberate rollback demonstration
-- Balances prior to failure test
SELECT account_number, full_name, available_balance AS balance_before_rollback
FROM accounts a JOIN customers c USING (customer_id)
WHERE a.account_number IN ('P3-ALICE-001', 'P3-BOB-001')
ORDER BY account_number;

-- Attempt partial transfer: error injected after debit leg to test atomicity
-- Note: pgAdmin will display the simulated exception and abort the block cleanly
BEGIN;

DO $$
DECLARE
    v_tx    BIGINT;
    v_alice BIGINT;
    v_bob   BIGINT;
BEGIN
    SELECT account_id INTO v_alice FROM accounts WHERE account_number = 'P3-ALICE-001';
    SELECT account_id INTO v_bob   FROM accounts WHERE account_number = 'P3-BOB-001';

    PERFORM account_id FROM accounts WHERE account_id = LEAST(v_alice, v_bob)   FOR UPDATE;
    PERFORM account_id FROM accounts WHERE account_id = GREATEST(v_alice, v_bob) FOR UPDATE;

    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by)
    VALUES ('TXN-P3-ROLLBACK-001', 'TRANSFER', 'PENDING', 50000.00, 'NGN',
            v_alice, v_bob, 'p3:alice')
    RETURNING transaction_id INTO v_tx;

    -- Debit leg inserted and sender balance altered
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_alice, 'DEBIT', 50000.00, 'NGN', 1, 'Transfer out: Alice (partial)');

    UPDATE accounts SET available_balance = available_balance - 50000.00 WHERE account_id = v_alice;

    -- Simulated server/network crash before credit leg
    RAISE EXCEPTION 'Simulated network exception after debit leg: triggering atomic rollback';

    -- Unreachable code due to exception
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_bob, 'CREDIT', 50000.00, 'NGN', 2, 'Transfer in: Bob');

    UPDATE accounts SET available_balance = available_balance + 50000.00 WHERE account_id = v_bob;
END $$;

ROLLBACK;

-- Verify atomicity: balances unchanged, zero orphan records committed
SELECT account_number, full_name, available_balance AS balance_after_rollback
FROM accounts a JOIN customers c USING (customer_id)
WHERE a.account_number IN ('P3-ALICE-001', 'P3-BOB-001')
ORDER BY account_number;

SELECT transaction_ref, status FROM transactions WHERE transaction_ref = 'TXN-P3-ROLLBACK-001';

SELECT COUNT(*) AS orphan_ledger_count
FROM ledger_entries l
JOIN transactions t ON t.transaction_id = l.transaction_id
WHERE t.transaction_ref = 'TXN-P3-ROLLBACK-001';
