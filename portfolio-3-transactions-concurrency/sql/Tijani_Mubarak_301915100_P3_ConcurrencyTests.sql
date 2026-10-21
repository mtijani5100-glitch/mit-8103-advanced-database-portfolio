-- Portfolio 3: Transactions and Concurrency
-- Concurrency, isolation anomalies, and deadlock tests
-- Mubarak Tijani (301915100)

-- 1. Isolation level comparison: READ COMMITTED vs REPEATABLE READ

-- 1a. READ COMMITTED: demonstrates non-repeatable read
-- Run in Query Tab 1 (Session A)
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

SELECT account_number, available_balance AS read_1
FROM accounts WHERE account_number = 'P3-ALICE-001';

-- [Execute block 1c in Query Tab 2 to commit a concurrent update]

-- Re-executing in same transaction sees committed change
SELECT account_number, available_balance AS read_2_sees_committed_update
FROM accounts WHERE account_number = 'P3-ALICE-001';

ROLLBACK;


-- 1b. REPEATABLE READ: demonstrates snapshot isolation
-- Run in Query Tab 1 (Session A)
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

SELECT account_number, available_balance AS read_1
FROM accounts WHERE account_number = 'P3-ALICE-001';

-- [Execute block 1c in Query Tab 2 to commit a concurrent update]

-- Re-executing in same transaction sees unchanged snapshot value
SELECT account_number, available_balance AS read_2_snapshot_consistent
FROM accounts WHERE account_number = 'P3-ALICE-001';

ROLLBACK;


-- 1c. Concurrent committer for 1a and 1b
-- Run in Query Tab 2 (Session B)
BEGIN;
UPDATE accounts SET available_balance = available_balance + 1000.00
WHERE account_number = 'P3-ALICE-001';
COMMIT;

-- Revert adjustment after running the isolation comparison
BEGIN;
UPDATE accounts SET available_balance = available_balance - 1000.00
WHERE account_number = 'P3-ALICE-001';
COMMIT;


-- 2. Concurrent race test: competing transfers against Alice's balance
-- Both sessions attempt 100,000 NGN transfer; FOR UPDATE prevents overdraft

-- Session A (Tab 1): locks row first and posts transfer
BEGIN;
DO $$
DECLARE
    v_tx    BIGINT;
    v_alice BIGINT;
    v_bob   BIGINT;
    v_bal   NUMERIC;
BEGIN
    SELECT account_id INTO v_alice FROM accounts WHERE account_number = 'P3-ALICE-001';
    SELECT account_id INTO v_bob   FROM accounts WHERE account_number = 'P3-BOB-001';

    -- Exclusive row lock holds off concurrent sessions
    SELECT available_balance INTO v_bal
    FROM accounts WHERE account_id = v_alice FOR UPDATE;

    IF v_bal < 100000.00 THEN
        RAISE EXCEPTION 'Insufficient funds: available %', v_bal;
    END IF;

    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, posted_at)
    VALUES ('TXN-P3-RACE-A', 'TRANSFER', 'POSTED', 100000.00, 'NGN',
            v_alice, v_bob, 'p3:session_a', NOW())
    RETURNING transaction_id INTO v_tx;

    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES
        (v_tx, v_alice, 'DEBIT',  100000.00, 'NGN', 1, 'Race test: Session A debit Alice'),
        (v_tx, v_bob,   'CREDIT', 100000.00, 'NGN', 2, 'Race test: Session A credit Bob');

    UPDATE accounts SET available_balance = available_balance - 100000.00 WHERE account_id = v_alice;
    UPDATE accounts SET available_balance = available_balance + 100000.00 WHERE account_id = v_bob;

    RAISE NOTICE 'Session A: transfer posted, holding lock until commit.';
END $$;
COMMIT;


-- Session B (Tab 2): attempts debit while Session A is in-flight
-- Blocks until Tab 1 commits, then re-checks balance under lock
BEGIN;
DO $$
DECLARE
    v_tx    BIGINT;
    v_alice BIGINT;
    v_bob   BIGINT;
    v_bal   NUMERIC;
BEGIN
    SELECT account_id INTO v_alice FROM accounts WHERE account_number = 'P3-ALICE-001';
    SELECT account_id INTO v_bob   FROM accounts WHERE account_number = 'P3-BOB-001';

    SELECT available_balance INTO v_bal
    FROM accounts WHERE account_id = v_alice FOR UPDATE;

    IF v_bal < 100000.00 THEN
        RAISE NOTICE 'Session B: insufficient balance after concurrent debit (available: %). Recording FAILED.', v_bal;
        INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
            source_account_id, destination_account_id, initiated_by, failure_reason)
        VALUES ('TXN-P3-RACE-B', 'TRANSFER', 'FAILED', 100000.00, 'NGN',
                v_alice, v_bob, 'p3:session_b',
                FORMAT('Insufficient funds: available NGN %s', v_bal));
        RETURN;
    END IF;

    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, posted_at)
    VALUES ('TXN-P3-RACE-B', 'TRANSFER', 'POSTED', 100000.00, 'NGN',
            v_alice, v_bob, 'p3:session_b', NOW())
    RETURNING transaction_id INTO v_tx;

    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES
        (v_tx, v_alice, 'DEBIT',  100000.00, 'NGN', 1, 'Race test: Session B debit Alice'),
        (v_tx, v_bob,   'CREDIT', 100000.00, 'NGN', 2, 'Race test: Session B credit Bob');

    UPDATE accounts SET available_balance = available_balance - 100000.00 WHERE account_id = v_alice;
    UPDATE accounts SET available_balance = available_balance + 100000.00 WHERE account_id = v_bob;
END $$;
COMMIT;

-- Verify no overdraft occurred
SELECT account_number, full_name, available_balance AS balance_post_race
FROM accounts a JOIN customers c USING (customer_id)
WHERE a.account_number IN ('P3-ALICE-001', 'P3-BOB-001')
ORDER BY account_number;

SELECT transaction_ref, status, failure_reason
FROM transactions
WHERE transaction_ref IN ('TXN-P3-RACE-A', 'TXN-P3-RACE-B')
ORDER BY created_at;


-- 3. Deadlock simulation and resolution

-- 3a. Unsafe reverse lock ordering (reproduces deadlock)
-- Tab 1 (Session A): locks Alice then Charlie
BEGIN;
DO $$
DECLARE
    v_alice   BIGINT;
    v_charlie BIGINT;
BEGIN
    SELECT account_id INTO v_alice   FROM accounts WHERE account_number = 'P3-ALICE-001';
    SELECT account_id INTO v_charlie FROM accounts WHERE account_number = 'P3-CHARLIE-001';

    PERFORM account_id FROM accounts WHERE account_id = v_alice   FOR UPDATE;
    PERFORM pg_sleep(2);
    PERFORM account_id FROM accounts WHERE account_id = v_charlie FOR UPDATE;
END $$;
COMMIT;

-- Tab 2 (Session B): locks Charlie then Alice simultaneously with Tab 1
BEGIN;
DO $$
DECLARE
    v_alice   BIGINT;
    v_charlie BIGINT;
BEGIN
    SELECT account_id INTO v_alice   FROM accounts WHERE account_number = 'P3-ALICE-001';
    SELECT account_id INTO v_charlie FROM accounts WHERE account_number = 'P3-CHARLIE-001';

    PERFORM account_id FROM accounts WHERE account_id = v_charlie FOR UPDATE;
    PERFORM pg_sleep(2);
    PERFORM account_id FROM accounts WHERE account_id = v_alice   FOR UPDATE;
END $$;
COMMIT;


-- 3b. Safe ascending lock order: eliminates cyclic dependencies
-- Tab 1 (Session A)
BEGIN;
DO $$
DECLARE
    v_alice   BIGINT;
    v_charlie BIGINT;
BEGIN
    SELECT account_id INTO v_alice   FROM accounts WHERE account_number = 'P3-ALICE-001';
    SELECT account_id INTO v_charlie FROM accounts WHERE account_number = 'P3-CHARLIE-001';

    -- Sort lock acquisition by account_id
    PERFORM account_id FROM accounts WHERE account_id = LEAST(v_alice, v_charlie)    FOR UPDATE;
    PERFORM account_id FROM accounts WHERE account_id = GREATEST(v_alice, v_charlie) FOR UPDATE;
END $$;
ROLLBACK;

-- Tab 2 (Session B): uses identical ordering, queues without deadlock
BEGIN;
DO $$
DECLARE
    v_alice   BIGINT;
    v_charlie BIGINT;
BEGIN
    SELECT account_id INTO v_alice   FROM accounts WHERE account_number = 'P3-ALICE-001';
    SELECT account_id INTO v_charlie FROM accounts WHERE account_number = 'P3-CHARLIE-001';

    PERFORM account_id FROM accounts WHERE account_id = LEAST(v_alice, v_charlie)    FOR UPDATE;
    PERFORM account_id FROM accounts WHERE account_id = GREATEST(v_alice, v_charlie) FOR UPDATE;
END $$;
ROLLBACK;


-- 4. Audit reconciliation query
-- Confirms zero drift between cached balances and computed ledger history
SELECT
    a.account_number,
    c.full_name,
    a.available_balance                                  AS cached_balance,
    COALESCE(SUM(CASE WHEN l.entry_side = 'CREDIT' THEN l.amount ELSE 0 END), 0)
    - COALESCE(SUM(CASE WHEN l.entry_side = 'DEBIT'  THEN l.amount ELSE 0 END), 0) AS ledger_balance,
    a.available_balance
    - (COALESCE(SUM(CASE WHEN l.entry_side = 'CREDIT' THEN l.amount ELSE 0 END), 0)
       - COALESCE(SUM(CASE WHEN l.entry_side = 'DEBIT'  THEN l.amount ELSE 0 END), 0)) AS drift
FROM accounts a
JOIN customers c ON c.customer_id = a.customer_id
LEFT JOIN ledger_entries l ON l.account_id = a.account_id
WHERE a.account_number LIKE 'P3-%'
GROUP BY a.account_id, a.account_number, c.full_name, a.available_balance
ORDER BY a.account_number;
