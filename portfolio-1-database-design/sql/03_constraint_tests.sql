-- =============================================================================
-- Portfolio 1: Database Design and Modelling
-- LedgerSpring Digital Bank (LSDB) — Constraint and Relationship Tests
-- MIT 8103 Advanced Database Systems
--
-- Run AFTER 02_seed_data.sql
-- Each test demonstrates that the database enforces a specific business rule.
-- Account IDs are looked up by account_number — never hardcoded.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- TEST 1 — Duplicate account number must be rejected (UNIQUE constraint)
-- Expected: PASS
-- ---------------------------------------------------------------------------
\echo '--- TEST 1: Duplicate account number (expect PASS) ---'
DO $$
DECLARE v_cid BIGINT;
BEGIN
    SELECT customer_id INTO v_cid FROM customers WHERE full_name = 'Amaka Okonkwo';
    BEGIN
        INSERT INTO accounts (customer_id, account_number, account_kind,
                              account_type, currency, available_balance, status)
        VALUES (v_cid, '1000000001', 'CUSTOMER', 'SAVINGS', 'NGN', 0, 'ACTIVE');
        RAISE NOTICE 'FAIL: duplicate account number was accepted';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'PASS: unique constraint rejected duplicate account number.';
    END;
END $$;

-- ---------------------------------------------------------------------------
-- TEST 2 — Account referencing a non-existent customer must be rejected (FK)
-- Expected: PASS
-- ---------------------------------------------------------------------------
\echo '--- TEST 2: FK – orphan customer_id (expect PASS) ---'
DO $$
BEGIN
    BEGIN
        INSERT INTO accounts (customer_id, account_number, account_kind,
                              account_type, currency, available_balance, status)
        VALUES (999999, '9999999999', 'CUSTOMER', 'SAVINGS', 'NGN', 0, 'ACTIVE');
        RAISE NOTICE 'FAIL: orphan FK was accepted';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'PASS: FK constraint rejected non-existent customer_id.';
    END;
END $$;

-- ---------------------------------------------------------------------------
-- TEST 3 — CUSTOMER account without customer_id must be rejected (CHECK)
-- Expected: PASS
-- ---------------------------------------------------------------------------
\echo '--- TEST 3: CUSTOMER account without customer_id (expect PASS) ---'
DO $$
BEGIN
    BEGIN
        INSERT INTO accounts (customer_id, account_number, account_kind,
                              account_type, currency, available_balance, status)
        VALUES (NULL, '8888888888', 'CUSTOMER', 'SAVINGS', 'NGN', 0, 'ACTIVE');
        RAISE NOTICE 'FAIL: CUSTOMER account with NULL customer_id was accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS: check constraint rejected CUSTOMER account with NULL customer_id.';
    END;
END $$;

-- ---------------------------------------------------------------------------
-- TEST 4 — SETTLEMENT account with a customer_id must be rejected (CHECK)
-- Expected: PASS
-- ---------------------------------------------------------------------------
\echo '--- TEST 4: SETTLEMENT account with a customer_id (expect PASS) ---'
DO $$
DECLARE v_cid BIGINT;
BEGIN
    SELECT customer_id INTO v_cid FROM customers WHERE full_name = 'Tunde Bankole';
    BEGIN
        INSERT INTO accounts (customer_id, account_number, account_kind,
                              account_type, currency, available_balance, status)
        VALUES (v_cid, 'SYS9999999', 'SETTLEMENT', NULL, 'NGN', NULL, 'ACTIVE');
        RAISE NOTICE 'FAIL: SETTLEMENT account with customer_id was accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS: check constraint rejected SETTLEMENT account with customer_id.';
    END;
END $$;

-- ---------------------------------------------------------------------------
-- TEST 5 — Zero-amount transaction must be rejected (CHECK amount > 0)
-- Expected: PASS
-- ---------------------------------------------------------------------------
\echo '--- TEST 5: Zero amount transaction (expect PASS) ---'
DO $$
DECLARE
    v_src BIGINT;
    v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '1000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '2000000001';
    BEGIN
        INSERT INTO transactions
            (transaction_ref, transaction_type, status, amount, currency,
             source_account_id, destination_account_id, initiated_by)
        VALUES ('TXN-FAIL-ZERO', 'TRANSFER', 'PENDING', 0, 'NGN', v_src, v_dst, 'test');
        RAISE NOTICE 'FAIL: zero amount was accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS: check constraint rejected zero amount transaction.';
    END;
END $$;

-- ---------------------------------------------------------------------------
-- TEST 6 — Same-account transfer must be rejected (CHECK accounts differ)
-- Expected: PASS
-- ---------------------------------------------------------------------------
\echo '--- TEST 6: Same-account transfer (expect PASS) ---'
DO $$
DECLARE v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_acct FROM accounts WHERE account_number = '1000000001';
    BEGIN
        INSERT INTO transactions
            (transaction_ref, transaction_type, status, amount, currency,
             source_account_id, destination_account_id, initiated_by)
        VALUES ('TXN-FAIL-SAME', 'TRANSFER', 'PENDING', 5000, 'NGN', v_acct, v_acct, 'test');
        RAISE NOTICE 'FAIL: same-account transfer was accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS: check constraint rejected same-account transfer.';
    END;
END $$;

-- ---------------------------------------------------------------------------
-- TEST 7 — Duplicate transaction_ref must be rejected (UNIQUE)
-- Expected: PASS
-- ---------------------------------------------------------------------------
\echo '--- TEST 7: Duplicate transaction_ref (expect PASS) ---'
DO $$
DECLARE
    v_src BIGINT;
    v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '1000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '2000000001';
    BEGIN
        INSERT INTO transactions
            (transaction_ref, transaction_type, status, amount, currency,
             source_account_id, destination_account_id, initiated_by)
        VALUES ('TXN-2026-TRF-001', 'TRANSFER', 'PENDING', 100, 'NGN', v_src, v_dst, 'test');
        RAISE NOTICE 'FAIL: duplicate transaction_ref was accepted';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'PASS: unique constraint rejected duplicate transaction_ref.';
    END;
END $$;

-- ---------------------------------------------------------------------------
-- TEST 8 — Double reversal of same original transaction must be rejected (UNIQUE)
-- TXN-2026-TRF-001 was already reversed in seed data (TXN-2026-REV-001).
-- Expected: PASS
-- ---------------------------------------------------------------------------
\echo '--- TEST 8: Double-reversal attempt (expect PASS) ---'
DO $$
DECLARE
    v_orig_id    BIGINT;
    v_chukwudi_s BIGINT;
    v_amaka_s    BIGINT;
BEGIN
    SELECT transaction_id INTO v_orig_id    FROM transactions WHERE transaction_ref = 'TXN-2026-TRF-001';
    SELECT account_id     INTO v_chukwudi_s FROM accounts WHERE account_number = '2000000001';
    SELECT account_id     INTO v_amaka_s    FROM accounts WHERE account_number = '1000000001';
    BEGIN
        INSERT INTO transactions
            (transaction_ref, transaction_type, status, amount, currency,
             source_account_id, destination_account_id,
             reversal_of_transaction_id, initiated_by)
        VALUES ('TXN-2026-REV-DUPE', 'REVERSAL', 'PENDING', 50000, 'NGN',
                v_chukwudi_s, v_amaka_s, v_orig_id, 'staff:bad');
        RAISE NOTICE 'FAIL: second reversal of same transaction was accepted';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'PASS: unique constraint rejected second reversal of the same transaction.';
    END;
END $$;

-- ---------------------------------------------------------------------------
-- TEST 9 — Ledger entry with zero amount must be rejected (CHECK amount > 0)
-- Expected: PASS
-- ---------------------------------------------------------------------------
\echo '--- TEST 9: Zero-amount ledger entry (expect PASS) ---'
DO $$
DECLARE
    v_tx_id BIGINT;
    v_acct  BIGINT;
BEGIN
    SELECT transaction_id INTO v_tx_id FROM transactions WHERE transaction_ref = 'TXN-2026-TRF-003';
    SELECT account_id     INTO v_acct  FROM accounts WHERE account_number = '1000000001';
    BEGIN
        INSERT INTO ledger_entries
            (transaction_id, account_id, entry_side, amount, currency, line_number)
        VALUES (v_tx_id, v_acct, 'DEBIT', 0, 'NGN', 99);
        RAISE NOTICE 'FAIL: zero-amount ledger entry was accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS: check constraint rejected zero-amount ledger entry.';
    END;
END $$;

-- ---------------------------------------------------------------------------
-- TEST 10 — Duplicate idempotency scope/key must be rejected (UNIQUE)
-- Expected: PASS
-- ---------------------------------------------------------------------------
\echo '--- TEST 10: Duplicate idempotency scope/key (expect PASS) ---'
DO $$
BEGIN
    BEGIN
        INSERT INTO idempotency_keys (scope, idem_key, request_hash)
        VALUES ('customer:amaka', 'idem-trx-001', md5('different payload'));
        RAISE NOTICE 'FAIL: duplicate idempotency key was accepted';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'PASS: unique constraint rejected duplicate idempotency scope/key.';
    END;
END $$;

-- ---------------------------------------------------------------------------
-- TEST 11 — Valid reversal row can be created and rolled back safely
-- Expected: PASS (row accepted, then rolled back to keep seed data clean)
-- ---------------------------------------------------------------------------
\echo '--- TEST 11: Valid reversal row accepted then rolled back (expect PASS) ---'
DO $$
DECLARE
    v_orig_id BIGINT;
    v_src     BIGINT;
    v_dst     BIGINT;
    v_rev_id  BIGINT;
BEGIN
    -- TXN-2026-TRF-003 (Amaka → Tunde) has not been reversed yet
    SELECT transaction_id INTO v_orig_id FROM transactions WHERE transaction_ref = 'TXN-2026-TRF-003';
    SELECT account_id     INTO v_src     FROM accounts WHERE account_number = '6000000001';
    SELECT account_id     INTO v_dst     FROM accounts WHERE account_number = '1000000001';

    INSERT INTO transactions
        (transaction_ref, transaction_type, status, amount, currency,
         source_account_id, destination_account_id,
         reversal_of_transaction_id, initiated_by)
    VALUES ('TXN-TEST-REV-VALID', 'REVERSAL', 'PENDING', 30000, 'NGN',
            v_src, v_dst, v_orig_id, 'staff:test')
    RETURNING transaction_id INTO v_rev_id;

    RAISE NOTICE 'PASS: valid reversal row accepted (transaction_id=%). Rolling back.', v_rev_id;
    RAISE EXCEPTION '__ROLLBACK__';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLERRM = '__ROLLBACK__' THEN
            RAISE NOTICE 'INFO: test transaction rolled back — seed data unchanged.';
        ELSE
            RAISE NOTICE 'FAIL: unexpected error — %', SQLERRM;
        END IF;
END $$;

-- ---------------------------------------------------------------------------
-- FINAL SUMMARY — Row counts and balance check
-- ---------------------------------------------------------------------------
\echo '--- SUMMARY: Row counts ---'
SELECT 'customers'        AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'accounts',         COUNT(*) FROM accounts
UNION ALL
SELECT 'transactions',     COUNT(*) FROM transactions
UNION ALL
SELECT 'ledger_entries',   COUNT(*) FROM ledger_entries
UNION ALL
SELECT 'idempotency_keys', COUNT(*) FROM idempotency_keys
UNION ALL
SELECT 'audit_logs',       COUNT(*) FROM audit_logs
ORDER BY table_name;

\echo '--- Transactions by status ---'
SELECT status, COUNT(*) FROM transactions GROUP BY status ORDER BY status;
