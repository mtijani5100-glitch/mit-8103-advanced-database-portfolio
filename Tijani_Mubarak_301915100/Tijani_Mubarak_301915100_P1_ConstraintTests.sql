-- Integrity constraint tests for LedgerSpring Digital Bank (LSDB)

-- Test 1: Unique account number enforcement
\echo 'Running Test 1: Duplicate account number rejection'
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

-- Test 2: Foreign key violation on non-existent customer
\echo 'Running Test 2: Orphan customer_id foreign key rejection'
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

-- Test 3: CUSTOMER account without customer_id
\echo 'Running Test 3: Customer account without customer_id rejection'
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

-- Test 4: SETTLEMENT account with customer_id
\echo 'Running Test 4: Settlement account with customer_id rejection'
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

-- Test 5: Zero-amount transaction
\echo 'Running Test 5: Zero amount transaction rejection'
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

-- Test 6: Same source and destination account transfer
\echo 'Running Test 6: Same-account transfer rejection'
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

-- Test 7: Duplicate transaction reference
\echo 'Running Test 7: Duplicate transaction_ref rejection'
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

-- Test 8: Duplicate reversal attempt on the same original transaction
\echo 'Running Test 8: Double-reversal rejection'
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

-- Test 9: Zero-amount ledger entry
\echo 'Running Test 9: Zero-amount ledger entry rejection'
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

-- Test 10: Duplicate idempotency key within same scope
\echo 'Running Test 10: Duplicate idempotency scope/key rejection'
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

-- Test 11: Valid reversal creation and rollback
\echo 'Running Test 11: Valid reversal creation and rollback'
DO $$
DECLARE
    v_orig_id BIGINT;
    v_src     BIGINT;
    v_dst     BIGINT;
    v_rev_id  BIGINT;
BEGIN
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

-- Verification: table row counts
\echo 'Database summary after tests:'
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'accounts', COUNT(*) FROM accounts
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL
SELECT 'ledger_entries', COUNT(*) FROM ledger_entries
UNION ALL
SELECT 'idempotency_keys', COUNT(*) FROM idempotency_keys
UNION ALL
SELECT 'audit_logs', COUNT(*) FROM audit_logs
ORDER BY table_name;
