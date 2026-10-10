-- =============================================================================
-- Portfolio 1: Database Design and Modelling
-- LedgerSpring Digital Bank (LSDB) — Synthetic Seed Data
-- MIT 8103 Advanced Database Systems
--
-- Run AFTER 01_create_schema.sql
-- All data is fictional and generated for academic demonstration only.
--
-- Design contract:
--   • ALL customer accounts start at 0.00 available_balance.
--   • Every opening balance is established by a DEPOSIT transaction with
--     matching ledger entries — never by a "magical" initial value.
--   • The reconciliation query at the end should show 0.00 discrepancy
--     for every customer account.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. CUSTOMERS  (6 synthetic profiles)
-- ---------------------------------------------------------------------------
INSERT INTO customers (full_name, email, phone, status) VALUES
  ('Amaka Okonkwo',     'amaka.okonkwo@lsdb-demo.test',     '08012345001', 'ACTIVE'),
  ('Chukwudi Eze',      'chukwudi.eze@lsdb-demo.test',      '08012345002', 'ACTIVE'),
  ('Funmilayo Adeyemi', 'funmilayo.adeyemi@lsdb-demo.test', '08012345003', 'ACTIVE'),
  ('Emeka Nwosu',       NULL,                                '08012345004', 'ACTIVE'),
  ('Blessing Okafor',   'blessing.okafor@lsdb-demo.test',   NULL,          'SUSPENDED'),
  ('Tunde Bankole',     'tunde.bankole@lsdb-demo.test',     '08012345006', 'ACTIVE');

-- ---------------------------------------------------------------------------
-- 2. ACCOUNTS  (all customer balances start at 0.00 — funded below)
-- ---------------------------------------------------------------------------
INSERT INTO accounts
    (customer_id, account_number, account_kind, account_type,
     currency, available_balance, status)
VALUES
  -- System accounts (customer_id NULL, balance NULL per schema CHECK)
  (NULL, 'SYS0000001', 'SETTLEMENT', NULL, 'NGN', NULL, 'ACTIVE'),
  (NULL, 'SYS0000002', 'SUSPENSE',   NULL, 'NGN', NULL, 'ACTIVE'),

  -- Amaka Okonkwo
  ((SELECT customer_id FROM customers WHERE full_name = 'Amaka Okonkwo'),
   '1000000001', 'CUSTOMER', 'SAVINGS', 'NGN', 0.00, 'ACTIVE'),
  ((SELECT customer_id FROM customers WHERE full_name = 'Amaka Okonkwo'),
   '1000000002', 'CUSTOMER', 'CURRENT', 'NGN', 0.00, 'ACTIVE'),

  -- Chukwudi Eze
  ((SELECT customer_id FROM customers WHERE full_name = 'Chukwudi Eze'),
   '2000000001', 'CUSTOMER', 'SAVINGS', 'NGN', 0.00, 'ACTIVE'),

  -- Funmilayo Adeyemi
  ((SELECT customer_id FROM customers WHERE full_name = 'Funmilayo Adeyemi'),
   '3000000001', 'CUSTOMER', 'CURRENT', 'NGN', 0.00, 'ACTIVE'),

  -- Emeka Nwosu
  ((SELECT customer_id FROM customers WHERE full_name = 'Emeka Nwosu'),
   '4000000001', 'CUSTOMER', 'SAVINGS', 'NGN', 0.00, 'ACTIVE'),

  -- Blessing Okafor (SUSPENDED customer — account still active for balance holding)
  ((SELECT customer_id FROM customers WHERE full_name = 'Blessing Okafor'),
   '5000000001', 'CUSTOMER', 'SAVINGS', 'NGN', 0.00, 'ACTIVE'),

  -- Tunde Bankole
  ((SELECT customer_id FROM customers WHERE full_name = 'Tunde Bankole'),
   '6000000001', 'CUSTOMER', 'SAVINGS', 'NGN', 0.00, 'ACTIVE'),
  ((SELECT customer_id FROM customers WHERE full_name = 'Tunde Bankole'),
   '6000000002', 'CUSTOMER', 'CURRENT', 'NGN', 0.00, 'SUSPENDED');

-- ---------------------------------------------------------------------------
-- 3. OPENING BALANCE DEPOSITS  (one DO block per account for isolation)
--    Each block is atomic: transaction + two ledger entries + balance update.
-- ---------------------------------------------------------------------------

-- FND-001: Deposit NGN 500,000 → Amaka Savings (1000000001)
DO $$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '1000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-001', 'DEPOSIT', 'POSTED', 500000.00, 'NGN',
            v_settle, v_acct, 'system:seed', NOW()-INTERVAL '30 days', NOW()-INTERVAL '30 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number)
    VALUES (v_tx, v_settle, 'DEBIT', 500000.00, 'NGN', 1),
           (v_tx, v_acct,   'CREDIT', 500000.00, 'NGN', 2);
    UPDATE accounts SET available_balance = available_balance + 500000.00 WHERE account_id = v_acct;
END $$;

-- FND-002: Deposit NGN 120,000 → Amaka Current (1000000002)
DO $$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '1000000002';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-002', 'DEPOSIT', 'POSTED', 120000.00, 'NGN',
            v_settle, v_acct, 'system:seed', NOW()-INTERVAL '30 days', NOW()-INTERVAL '30 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number)
    VALUES (v_tx, v_settle, 'DEBIT', 120000.00, 'NGN', 1),
           (v_tx, v_acct,   'CREDIT', 120000.00, 'NGN', 2);
    UPDATE accounts SET available_balance = available_balance + 120000.00 WHERE account_id = v_acct;
END $$;

-- FND-003: Deposit NGN 750,000 → Chukwudi Savings (2000000001)
DO $$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '2000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-003', 'DEPOSIT', 'POSTED', 750000.00, 'NGN',
            v_settle, v_acct, 'system:seed', NOW()-INTERVAL '30 days', NOW()-INTERVAL '30 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number)
    VALUES (v_tx, v_settle, 'DEBIT', 750000.00, 'NGN', 1),
           (v_tx, v_acct,   'CREDIT', 750000.00, 'NGN', 2);
    UPDATE accounts SET available_balance = available_balance + 750000.00 WHERE account_id = v_acct;
END $$;

-- FND-004: Deposit NGN 80,000 → Funmilayo Current (3000000001)
DO $$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '3000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-004', 'DEPOSIT', 'POSTED', 80000.00, 'NGN',
            v_settle, v_acct, 'system:seed', NOW()-INTERVAL '30 days', NOW()-INTERVAL '30 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number)
    VALUES (v_tx, v_settle, 'DEBIT', 80000.00, 'NGN', 1),
           (v_tx, v_acct,   'CREDIT', 80000.00, 'NGN', 2);
    UPDATE accounts SET available_balance = available_balance + 80000.00 WHERE account_id = v_acct;
END $$;

-- FND-005: Deposit NGN 200,000 → Emeka Savings (4000000001)
DO $$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '4000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-005', 'DEPOSIT', 'POSTED', 200000.00, 'NGN',
            v_settle, v_acct, 'system:seed', NOW()-INTERVAL '30 days', NOW()-INTERVAL '30 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number)
    VALUES (v_tx, v_settle, 'DEBIT', 200000.00, 'NGN', 1),
           (v_tx, v_acct,   'CREDIT', 200000.00, 'NGN', 2);
    UPDATE accounts SET available_balance = available_balance + 200000.00 WHERE account_id = v_acct;
END $$;

-- FND-006: Deposit NGN 15,000 → Blessing Savings (5000000001)
DO $$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '5000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-006', 'DEPOSIT', 'POSTED', 15000.00, 'NGN',
            v_settle, v_acct, 'system:seed', NOW()-INTERVAL '30 days', NOW()-INTERVAL '30 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number)
    VALUES (v_tx, v_settle, 'DEBIT', 15000.00, 'NGN', 1),
           (v_tx, v_acct,   'CREDIT', 15000.00, 'NGN', 2);
    UPDATE accounts SET available_balance = available_balance + 15000.00 WHERE account_id = v_acct;
END $$;

-- FND-007: Deposit NGN 300,000 → Tunde Savings (6000000001)
DO $$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '6000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-007', 'DEPOSIT', 'POSTED', 300000.00, 'NGN',
            v_settle, v_acct, 'system:seed', NOW()-INTERVAL '30 days', NOW()-INTERVAL '30 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number)
    VALUES (v_tx, v_settle, 'DEBIT', 300000.00, 'NGN', 1),
           (v_tx, v_acct,   'CREDIT', 300000.00, 'NGN', 2);
    UPDATE accounts SET available_balance = available_balance + 300000.00 WHERE account_id = v_acct;
END $$;

-- FND-008: Deposit NGN 50,000 → Tunde Current (6000000002)
DO $$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '6000000002';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-008', 'DEPOSIT', 'POSTED', 50000.00, 'NGN',
            v_settle, v_acct, 'system:seed', NOW()-INTERVAL '30 days', NOW()-INTERVAL '30 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number)
    VALUES (v_tx, v_settle, 'DEBIT', 50000.00, 'NGN', 1),
           (v_tx, v_acct,   'CREDIT', 50000.00, 'NGN', 2);
    UPDATE accounts SET available_balance = available_balance + 50000.00 WHERE account_id = v_acct;
END $$;

-- ---------------------------------------------------------------------------
-- 4. OPERATIONAL TRANSACTIONS
-- ---------------------------------------------------------------------------

-- TXN-2026-TRF-001: Transfer NGN 50,000 — Amaka Savings → Chukwudi Savings
DO $$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '1000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '2000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-TRF-001', 'TRANSFER', 'POSTED', 50000.00, 'NGN',
            v_src, v_dst, 'customer:amaka', NOW()-INTERVAL '20 days', NOW()-INTERVAL '20 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src, 'DEBIT',  50000.00, 'NGN', 1, 'Transfer out: Amaka Savings'),
           (v_tx, v_dst, 'CREDIT', 50000.00, 'NGN', 2, 'Transfer in: Chukwudi Savings');
    UPDATE accounts SET available_balance = available_balance - 50000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 50000.00 WHERE account_id = v_dst;
    INSERT INTO audit_logs (actor, action, entity_type, entity_id, transaction_id, event_details)
    VALUES ('customer:amaka', 'TRANSACTION_POSTED', 'TRANSACTION', v_tx::TEXT, v_tx,
            jsonb_build_object('type', 'TRANSFER', 'from', '1000000001', 'to', '2000000001', 'amount_ngn', 50000));
END $$;

-- TXN-2026-TRF-002: FAILED transfer — Funmilayo tried NGN 100,000 with only NGN 80,000
DO $$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '3000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '2000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, failure_reason, created_at)
    VALUES ('TXN-2026-TRF-002', 'TRANSFER', 'FAILED', 100000.00, 'NGN',
            v_src, v_dst, 'customer:funmilayo',
            'INSUFFICIENT_FUNDS: available_balance 80000.00 < requested 100000.00',
            NOW()-INTERVAL '15 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO audit_logs (actor, action, entity_type, entity_id, transaction_id, event_details)
    VALUES ('customer:funmilayo', 'TRANSACTION_FAILED', 'TRANSACTION', v_tx::TEXT, v_tx,
            jsonb_build_object('reason', 'INSUFFICIENT_FUNDS'));
END $$;

-- TXN-2026-WDR-001: Withdrawal NGN 120,000 from Amaka Current
DO $$
DECLARE v_tx BIGINT; v_src BIGINT; v_settle BIGINT;
BEGIN
    SELECT account_id INTO v_src    FROM accounts WHERE account_number = '1000000002';
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-WDR-001', 'WITHDRAWAL', 'POSTED', 120000.00, 'NGN',
            v_src, v_settle, 'customer:amaka', NOW()-INTERVAL '10 days', NOW()-INTERVAL '10 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src,    'DEBIT',  120000.00, 'NGN', 1, 'Withdrawal: debit Amaka Current'),
           (v_tx, v_settle, 'CREDIT', 120000.00, 'NGN', 2, 'Withdrawal: credit settlement');
    UPDATE accounts SET available_balance = available_balance - 120000.00 WHERE account_id = v_src;
    INSERT INTO audit_logs (actor, action, entity_type, entity_id, transaction_id, event_details)
    VALUES ('customer:amaka', 'TRANSACTION_POSTED', 'TRANSACTION', v_tx::TEXT, v_tx,
            jsonb_build_object('type', 'WITHDRAWAL', 'amount_ngn', 120000));
END $$;

-- TXN-2026-TRF-003: Transfer NGN 30,000 — Amaka Savings → Tunde Savings
DO $$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '1000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '6000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-TRF-003', 'TRANSFER', 'POSTED', 30000.00, 'NGN',
            v_src, v_dst, 'customer:amaka', NOW()-INTERVAL '5 days', NOW()-INTERVAL '5 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src, 'DEBIT',  30000.00, 'NGN', 1, 'Transfer out: Amaka Savings'),
           (v_tx, v_dst, 'CREDIT', 30000.00, 'NGN', 2, 'Transfer in: Tunde Savings');
    UPDATE accounts SET available_balance = available_balance - 30000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 30000.00 WHERE account_id = v_dst;
    INSERT INTO audit_logs (actor, action, entity_type, entity_id, transaction_id, event_details)
    VALUES ('customer:amaka', 'TRANSACTION_POSTED', 'TRANSACTION', v_tx::TEXT, v_tx,
            jsonb_build_object('type', 'TRANSFER', 'from', '1000000001', 'to', '6000000001', 'amount_ngn', 30000));
END $$;

-- TXN-2026-REV-001: Reversal of TXN-2026-TRF-001 (Amaka→Chukwudi NGN 50,000)
DO $$
DECLARE v_orig BIGINT; v_rev BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT transaction_id INTO v_orig FROM transactions WHERE transaction_ref = 'TXN-2026-TRF-001';
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '2000000001'; -- Chukwudi debited
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '1000000001'; -- Amaka credited
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, reversal_of_transaction_id,
        initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-REV-001', 'REVERSAL', 'POSTED', 50000.00, 'NGN',
            v_src, v_dst, v_orig, 'staff:ops01', NOW()-INTERVAL '2 days', NOW()-INTERVAL '2 days')
    RETURNING transaction_id INTO v_rev;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_rev, v_src, 'DEBIT',  50000.00, 'NGN', 1, 'Reversal: debit Chukwudi Savings'),
           (v_rev, v_dst, 'CREDIT', 50000.00, 'NGN', 2, 'Reversal: credit Amaka Savings');
    UPDATE accounts SET available_balance = available_balance - 50000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 50000.00 WHERE account_id = v_dst;
    INSERT INTO audit_logs (actor, action, entity_type, entity_id, transaction_id, event_details)
    VALUES ('staff:ops01', 'REVERSAL_POSTED', 'TRANSACTION', v_rev::TEXT, v_rev,
            jsonb_build_object('original_ref', 'TXN-2026-TRF-001', 'reason', 'Customer request: incorrect recipient'));
END $$;

-- ---------------------------------------------------------------------------
-- 5. IDEMPOTENCY_KEYS
-- ---------------------------------------------------------------------------
INSERT INTO idempotency_keys (scope, idem_key, request_hash, transaction_id)
SELECT 'customer:amaka', 'idem-trx-001',
       md5('TRANSFER|1000000001|2000000001|50000.00|NGN'),
       transaction_id
FROM transactions WHERE transaction_ref = 'TXN-2026-TRF-001';

INSERT INTO idempotency_keys (scope, idem_key, request_hash, transaction_id)
SELECT 'customer:amaka', 'idem-wdr-001',
       md5('WITHDRAWAL|1000000002|120000.00|NGN'),
       transaction_id
FROM transactions WHERE transaction_ref = 'TXN-2026-WDR-001';

-- ---------------------------------------------------------------------------
-- 6. BALANCE RECONCILIATION
--    Compares cached available_balance against ledger-derived net credit.
--    Expected discrepancy = 0.00 for every customer account.
--
--    Expected final balances:
--      1000000001 Amaka Savings : 500000 - 50000 - 30000 + 50000 = 470000
--      1000000002 Amaka Current : 120000 - 120000              =      0
--      2000000001 Chukwudi Sav  : 750000 + 50000 - 50000       = 750000
--      3000000001 Funmilayo Cur :  80000 (no operational txns) =  80000
--      4000000001 Emeka Sav     : 200000 (no operational txns) = 200000
--      5000000001 Blessing Sav  :  15000 (no operational txns) =  15000
--      6000000001 Tunde Sav     : 300000 + 30000               = 330000
--      6000000002 Tunde Cur     :  50000 (no operational txns) =  50000
-- ---------------------------------------------------------------------------
\echo '--- Balance reconciliation: cached vs ledger-derived ---'
SELECT
    a.account_number,
    c.full_name,
    a.available_balance                              AS cached_balance,
    COALESCE(
        SUM(CASE WHEN le.entry_side = 'CREDIT' THEN  le.amount
                 WHEN le.entry_side = 'DEBIT'  THEN -le.amount
                 ELSE 0 END
        ), 0
    )                                                AS ledger_derived_balance,
    a.available_balance - COALESCE(
        SUM(CASE WHEN le.entry_side = 'CREDIT' THEN  le.amount
                 WHEN le.entry_side = 'DEBIT'  THEN -le.amount
                 ELSE 0 END
        ), 0
    )                                                AS discrepancy
FROM  accounts a
JOIN  customers c ON a.customer_id = c.customer_id
LEFT JOIN ledger_entries le ON le.account_id = a.account_id
WHERE a.account_kind = 'CUSTOMER'
GROUP BY a.account_id, a.account_number, c.full_name, a.available_balance
ORDER BY a.account_number;
