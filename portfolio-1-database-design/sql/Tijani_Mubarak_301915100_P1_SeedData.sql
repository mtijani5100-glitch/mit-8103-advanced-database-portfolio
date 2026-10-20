-- Seed data for LedgerSpring Digital Bank (LSDB)

-- 1. Customers
INSERT INTO customers (full_name, email, phone, status, created_at) VALUES
  ('Amaka Okonkwo',     'amaka.okonkwo@lsdb-demo.ng',     '08023451001', 'ACTIVE',    NOW() - INTERVAL '60 days'),
  ('Chukwudi Eze',      'chukwudi.eze@lsdb-demo.ng',      '08033452002', 'ACTIVE',    NOW() - INTERVAL '58 days'),
  ('Funmilayo Adeyemi', 'funmilayo.adeyemi@lsdb-demo.ng', '08053453003', 'ACTIVE',    NOW() - INTERVAL '55 days'),
  ('Emeka Nwosu',       'emeka.nwosu@lsdb-demo.ng',       '08183454004', 'ACTIVE',    NOW() - INTERVAL '50 days'),
  ('Blessing Okafor',   'blessing.okafor@lsdb-demo.ng',   '07033455005', 'SUSPENDED', NOW() - INTERVAL '45 days'),
  ('Tunde Bankole',     'tunde.bankole@lsdb-demo.ng',     '08023456006', 'ACTIVE',    NOW() - INTERVAL '42 days'),
  ('Ibrahim Danjuma',   'ibrahim.danjuma@lsdb-demo.ng',   '08063457007', 'ACTIVE',    NOW() - INTERVAL '40 days'),
  ('Zainab Abubakar',   'zainab.abubakar@lsdb-demo.ng',   '08123458008', 'ACTIVE',    NOW() - INTERVAL '35 days'),
  ('Tamuno Briggs',     'tamuno.briggs@lsdb-demo.ng',     '08033459009', 'ACTIVE',    NOW() - INTERVAL '30 days'),
  ('Osahon Igbinedion', 'osahon.igbinedion@lsdb-demo.ng', '08073450010', 'ACTIVE',    NOW() - INTERVAL '28 days'),
  ('Aisha Mohammed',    'aisha.mohammed@lsdb-demo.ng',    '08093450011', 'ACTIVE',    NOW() - INTERVAL '25 days'),
  ('Babatunde Adeleke', 'babatunde.adeleke@lsdb-demo.ng', '08143450012', 'ACTIVE',    NOW() - INTERVAL '20 days');

-- 2. Accounts
INSERT INTO accounts
    (customer_id, account_number, account_kind, account_type, currency, available_balance, status, created_at)
VALUES
  (NULL, 'SYS0000001', 'SETTLEMENT', NULL, 'NGN', NULL, 'ACTIVE', NOW() - INTERVAL '60 days'),
  (NULL, 'SYS0000002', 'SUSPENSE',   NULL, 'NGN', NULL, 'ACTIVE', NOW() - INTERVAL '60 days'),
  (NULL, 'SYS0000003', 'SETTLEMENT', NULL, 'NGN', NULL, 'ACTIVE', NOW() - INTERVAL '60 days'),

  ((SELECT customer_id FROM customers WHERE full_name = 'Amaka Okonkwo'),
   '1000000001', 'CUSTOMER', 'SAVINGS', 'NGN', 0.00, 'ACTIVE', NOW() - INTERVAL '60 days'),
  ((SELECT customer_id FROM customers WHERE full_name = 'Amaka Okonkwo'),
   '1000000002', 'CUSTOMER', 'CURRENT', 'NGN', 0.00, 'ACTIVE', NOW() - INTERVAL '59 days'),

  ((SELECT customer_id FROM customers WHERE full_name = 'Chukwudi Eze'),
   '2000000001', 'CUSTOMER', 'SAVINGS', 'NGN', 0.00, 'ACTIVE', NOW() - INTERVAL '58 days'),
  ((SELECT customer_id FROM customers WHERE full_name = 'Chukwudi Eze'),
   '2000000002', 'CUSTOMER', 'CURRENT', 'NGN', 0.00, 'ACTIVE', NOW() - INTERVAL '57 days'),

  ((SELECT customer_id FROM customers WHERE full_name = 'Funmilayo Adeyemi'),
   '3000000001', 'CUSTOMER', 'CURRENT', 'NGN', 0.00, 'ACTIVE', NOW() - INTERVAL '55 days'),

  ((SELECT customer_id FROM customers WHERE full_name = 'Emeka Nwosu'),
   '4000000001', 'CUSTOMER', 'SAVINGS', 'NGN', 0.00, 'ACTIVE', NOW() - INTERVAL '50 days'),

  ((SELECT customer_id FROM customers WHERE full_name = 'Blessing Okafor'),
   '5000000001', 'CUSTOMER', 'SAVINGS', 'NGN', 0.00, 'ACTIVE', NOW() - INTERVAL '45 days'),

  ((SELECT customer_id FROM customers WHERE full_name = 'Tunde Bankole'),
   '6000000001', 'CUSTOMER', 'SAVINGS', 'NGN', 0.00, 'ACTIVE', NOW() - INTERVAL '42 days'),
  ((SELECT customer_id FROM customers WHERE full_name = 'Tunde Bankole'),
   '6000000002', 'CUSTOMER', 'CURRENT', 'NGN', 0.00, 'SUSPENDED', NOW() - INTERVAL '40 days'),

  ((SELECT customer_id FROM customers WHERE full_name = 'Ibrahim Danjuma'),
   '7000000001', 'CUSTOMER', 'CURRENT', 'NGN', 0.00, 'ACTIVE', NOW() - INTERVAL '39 days'),

  ((SELECT customer_id FROM customers WHERE full_name = 'Zainab Abubakar'),
   '8000000001', 'CUSTOMER', 'SAVINGS', 'NGN', 0.00, 'ACTIVE', NOW() - INTERVAL '35 days'),

  ((SELECT customer_id FROM customers WHERE full_name = 'Tamuno Briggs'),
   '9000000001', 'CUSTOMER', 'CURRENT', 'NGN', 0.00, 'ACTIVE', NOW() - INTERVAL '30 days'),

  ((SELECT customer_id FROM customers WHERE full_name = 'Osahon Igbinedion'),
   '9100000001', 'CUSTOMER', 'SAVINGS', 'NGN', 0.00, 'ACTIVE', NOW() - INTERVAL '28 days'),

  ((SELECT customer_id FROM customers WHERE full_name = 'Aisha Mohammed'),
   '9200000001', 'CUSTOMER', 'CURRENT', 'NGN', 0.00, 'ACTIVE', NOW() - INTERVAL '25 days'),

  ((SELECT customer_id FROM customers WHERE full_name = 'Babatunde Adeleke'),
   '9300000001', 'CUSTOMER', 'CURRENT', 'NGN', 0.00, 'ACTIVE', NOW() - INTERVAL '20 days');

-- 3. Initial funding deposits

-- FND-001: Amaka Okonkwo (Savings)
DO $seed$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '1000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-001', 'DEPOSIT', 'POSTED', 500000.00, 'NGN',
            v_settle, v_acct, 'nip:central_switch', NOW() - INTERVAL '40 days', NOW() - INTERVAL '40 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_settle, 'DEBIT',  500000.00, 'NGN', 1, 'Inbound NIP clearing: debit settlement'),
           (v_tx, v_acct,   'CREDIT', 500000.00, 'NGN', 2, 'Salary credit: Amaka Okonkwo');
    UPDATE accounts SET available_balance = available_balance + 500000.00 WHERE account_id = v_acct;
    INSERT INTO audit_logs (actor, action, entity_type, entity_id, transaction_id, event_details)
    VALUES ('nip:switch', 'FUNDS_DEPOSITED', 'TRANSACTION', v_tx::TEXT, v_tx,
            jsonb_build_object('channel', 'NIP_INWARD', 'origin_bank', '058_GTCO', 'narration', 'SALARY/TECHCORP/OCT2026'));
END $seed$;

-- FND-002: Amaka Okonkwo (Current)
DO $seed$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '1000000002';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-002', 'DEPOSIT', 'POSTED', 120000.00, 'NGN',
            v_settle, v_acct, 'nip:central_switch', NOW() - INTERVAL '38 days', NOW() - INTERVAL '38 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_settle, 'DEBIT',  120000.00, 'NGN', 1, 'Inbound NIP clearing: debit settlement'),
           (v_tx, v_acct,   'CREDIT', 120000.00, 'NGN', 2, 'Consulting fee: Amaka Current');
    UPDATE accounts SET available_balance = available_balance + 120000.00 WHERE account_id = v_acct;
END $seed$;

-- FND-003: Chukwudi Eze (Savings)
DO $seed$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '2000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-003', 'DEPOSIT', 'POSTED', 2500000.00, 'NGN',
            v_settle, v_acct, 'nip:central_switch', NOW() - INTERVAL '37 days', NOW() - INTERVAL '37 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_settle, 'DEBIT',  2500000.00, 'NGN', 1, 'Inbound NIP clearing: debit settlement'),
           (v_tx, v_acct,   'CREDIT', 2500000.00, 'NGN', 2, 'Commercial sales deposit: Chukwudi Eze');
    UPDATE accounts SET available_balance = available_balance + 2500000.00 WHERE account_id = v_acct;
END $seed$;

-- FND-004: Chukwudi Eze (Current)
DO $seed$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '2000000002';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-004', 'DEPOSIT', 'POSTED', 1000000.00, 'NGN',
            v_settle, v_acct, 'nip:central_switch', NOW() - INTERVAL '36 days', NOW() - INTERVAL '36 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_settle, 'DEBIT',  1000000.00, 'NGN', 1, 'Inbound NIP clearing: debit settlement'),
           (v_tx, v_acct,   'CREDIT', 1000000.00, 'NGN', 2, 'Merchant float: Chukwudi Current');
    UPDATE accounts SET available_balance = available_balance + 1000000.00 WHERE account_id = v_acct;
END $seed$;

-- FND-005: Funmilayo Adeyemi (Current)
DO $seed$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '3000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-005', 'DEPOSIT', 'POSTED', 850000.00, 'NGN',
            v_settle, v_acct, 'nip:central_switch', NOW() - INTERVAL '35 days', NOW() - INTERVAL '35 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_settle, 'DEBIT',  850000.00, 'NGN', 1, 'Inbound NIP clearing: debit settlement'),
           (v_tx, v_acct,   'CREDIT', 850000.00, 'NGN', 2, 'Professional retainer: Funmilayo Adeyemi');
    UPDATE accounts SET available_balance = available_balance + 850000.00 WHERE account_id = v_acct;
END $seed$;

-- FND-006: Emeka Nwosu (Savings)
DO $seed$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '4000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-006', 'DEPOSIT', 'POSTED', 600000.00, 'NGN',
            v_settle, v_acct, 'nip:central_switch', NOW() - INTERVAL '34 days', NOW() - INTERVAL '34 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_settle, 'DEBIT',  600000.00, 'NGN', 1, 'Inbound NIP clearing: debit settlement'),
           (v_tx, v_acct,   'CREDIT', 600000.00, 'NGN', 2, 'Commodity proceeds: Emeka Nwosu');
    UPDATE accounts SET available_balance = available_balance + 600000.00 WHERE account_id = v_acct;
END $seed$;

-- FND-007: Blessing Okafor (Savings)
DO $seed$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '5000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-007', 'DEPOSIT', 'POSTED', 150000.00, 'NGN',
            v_settle, v_acct, 'nip:central_switch', NOW() - INTERVAL '33 days', NOW() - INTERVAL '33 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_settle, 'DEBIT',  150000.00, 'NGN', 1, 'Inbound NIP clearing: debit settlement'),
           (v_tx, v_acct,   'CREDIT', 150000.00, 'NGN', 2, 'Design advance: Blessing Okafor');
    UPDATE accounts SET available_balance = available_balance + 150000.00 WHERE account_id = v_acct;
END $seed$;

-- FND-008: Tunde Bankole (Savings)
DO $seed$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '6000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-008', 'DEPOSIT', 'POSTED', 1800000.00, 'NGN',
            v_settle, v_acct, 'nip:central_switch', NOW() - INTERVAL '32 days', NOW() - INTERVAL '32 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_settle, 'DEBIT',  1800000.00, 'NGN', 1, 'Inbound NIP clearing: debit settlement'),
           (v_tx, v_acct,   'CREDIT', 1800000.00, 'NGN', 2, 'Construction milestone: Tunde Bankole');
    UPDATE accounts SET available_balance = available_balance + 1800000.00 WHERE account_id = v_acct;
END $seed$;

-- FND-009: Tunde Bankole (Current)
DO $seed$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '6000000002';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-009', 'DEPOSIT', 'POSTED', 50000.00, 'NGN',
            v_settle, v_acct, 'nip:central_switch', NOW() - INTERVAL '31 days', NOW() - INTERVAL '31 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_settle, 'DEBIT',  50000.00, 'NGN', 1, 'Inbound NIP clearing: debit settlement'),
           (v_tx, v_acct,   'CREDIT', 50000.00, 'NGN', 2, 'Fuel allocation: Tunde Current');
    UPDATE accounts SET available_balance = available_balance + 50000.00 WHERE account_id = v_acct;
END $seed$;

-- FND-010: Ibrahim Danjuma (Current)
DO $seed$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '7000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-010', 'DEPOSIT', 'POSTED', 1200000.00, 'NGN',
            v_settle, v_acct, 'nip:central_switch', NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_settle, 'DEBIT',  1200000.00, 'NGN', 1, 'Inbound NIP clearing: debit settlement'),
           (v_tx, v_acct,   'CREDIT', 1200000.00, 'NGN', 2, 'Haulage advance: Ibrahim Danjuma');
    UPDATE accounts SET available_balance = available_balance + 1200000.00 WHERE account_id = v_acct;
END $seed$;

-- FND-011: Zainab Abubakar (Savings)
DO $seed$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '8000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-011', 'DEPOSIT', 'POSTED', 420000.00, 'NGN',
            v_settle, v_acct, 'nip:central_switch', NOW() - INTERVAL '29 days', NOW() - INTERVAL '29 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_settle, 'DEBIT',  420000.00, 'NGN', 1, 'Inbound NIP clearing: debit settlement'),
           (v_tx, v_acct,   'CREDIT', 420000.00, 'NGN', 2, 'Hospitality booking: Zainab Abubakar');
    UPDATE accounts SET available_balance = available_balance + 420000.00 WHERE account_id = v_acct;
END $seed$;

-- FND-012: Tamuno Briggs (Current)
DO $seed$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '9000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-012', 'DEPOSIT', 'POSTED', 3500000.00, 'NGN',
            v_settle, v_acct, 'nip:central_switch', NOW() - INTERVAL '28 days', NOW() - INTERVAL '28 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_settle, 'DEBIT',  3500000.00, 'NGN', 1, 'Inbound NIP clearing: debit settlement'),
           (v_tx, v_acct,   'CREDIT', 3500000.00, 'NGN', 2, 'Subsea engineering fee: Tamuno Briggs');
    UPDATE accounts SET available_balance = available_balance + 3500000.00 WHERE account_id = v_acct;
END $seed$;

-- FND-013: Osahon Igbinedion (Savings)
DO $seed$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '9100000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-013', 'DEPOSIT', 'POSTED', 780000.00, 'NGN',
            v_settle, v_acct, 'nip:central_switch', NOW() - INTERVAL '27 days', NOW() - INTERVAL '27 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_settle, 'DEBIT',  780000.00, 'NGN', 1, 'Inbound NIP clearing: debit settlement'),
           (v_tx, v_acct,   'CREDIT', 780000.00, 'NGN', 2, 'Craftwork export: Osahon Igbinedion');
    UPDATE accounts SET available_balance = available_balance + 780000.00 WHERE account_id = v_acct;
END $seed$;

-- FND-014: Aisha Mohammed (Current)
DO $seed$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '9200000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-014', 'DEPOSIT', 'POSTED', 950000.00, 'NGN',
            v_settle, v_acct, 'nip:central_switch', NOW() - INTERVAL '26 days', NOW() - INTERVAL '26 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_settle, 'DEBIT',  950000.00, 'NGN', 1, 'Inbound NIP clearing: debit settlement'),
           (v_tx, v_acct,   'CREDIT', 950000.00, 'NGN', 2, 'Diagnostic clinic retainer: Aisha Mohammed');
    UPDATE accounts SET available_balance = available_balance + 950000.00 WHERE account_id = v_acct;
END $seed$;

-- FND-015: Babatunde Adeleke (Current)
DO $seed$
DECLARE v_tx BIGINT; v_settle BIGINT; v_acct BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_acct   FROM accounts WHERE account_number = '9300000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-FND-015', 'DEPOSIT', 'POSTED', 1600000.00, 'NGN',
            v_settle, v_acct, 'nip:central_switch', NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_settle, 'DEBIT',  1600000.00, 'NGN', 1, 'Inbound NIP clearing: debit settlement'),
           (v_tx, v_acct,   'CREDIT', 1600000.00, 'NGN', 2, 'POS merchant sweep: Babatunde Adeleke');
    UPDATE accounts SET available_balance = available_balance + 1600000.00 WHERE account_id = v_acct;
END $seed$;

-- 4. Operational transactions

-- TRF-001: Amaka Savings to Chukwudi Savings
DO $seed$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '1000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '2000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-TRF-001', 'TRANSFER', 'POSTED', 50000.00, 'NGN',
            v_src, v_dst, 'customer:amaka', NOW() - INTERVAL '24 days', NOW() - INTERVAL '24 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src, 'DEBIT',  50000.00, 'NGN', 1, 'Transfer out: Amaka Savings'),
           (v_tx, v_dst, 'CREDIT', 50000.00, 'NGN', 2, 'Transfer in: Chukwudi Savings');
    UPDATE accounts SET available_balance = available_balance - 50000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 50000.00 WHERE account_id = v_dst;
    INSERT INTO audit_logs (actor, action, entity_type, entity_id, transaction_id, event_details)
    VALUES ('customer:amaka', 'TRANSACTION_POSTED', 'TRANSACTION', v_tx::TEXT, v_tx,
            jsonb_build_object('type', 'TRANSFER', 'from', '1000000001', 'to', '2000000001', 'amount_ngn', 50000,
                               'narration', 'Laptop battery replacement'));
END $seed$;

-- REV-001: Reversal of TRF-001
DO $seed$
DECLARE v_orig BIGINT; v_rev BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT transaction_id INTO v_orig FROM transactions WHERE transaction_ref = 'TXN-2026-TRF-001';
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '2000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '1000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, reversal_of_transaction_id,
        initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-REV-001', 'REVERSAL', 'POSTED', 50000.00, 'NGN',
            v_src, v_dst, v_orig, 'staff:ops01', NOW() - INTERVAL '23 days', NOW() - INTERVAL '23 days')
    RETURNING transaction_id INTO v_rev;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_rev, v_src, 'DEBIT',  50000.00, 'NGN', 1, 'Reversal: debit Chukwudi Savings'),
           (v_rev, v_dst, 'CREDIT', 50000.00, 'NGN', 2, 'Reversal: credit Amaka Savings');
    UPDATE accounts SET available_balance = available_balance - 50000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 50000.00 WHERE account_id = v_dst;
    INSERT INTO audit_logs (actor, action, entity_type, entity_id, transaction_id, event_details)
    VALUES ('staff:ops01', 'REVERSAL_POSTED', 'TRANSACTION', v_rev::TEXT, v_rev,
            jsonb_build_object('original_ref', 'TXN-2026-TRF-001', 'reason', 'Customer dispute: wrong NUBAN digit entered'));
END $seed$;

-- TRF-002: Failed transfer (insufficient funds)
DO $seed$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '3000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '2000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, failure_reason, created_at)
    VALUES ('TXN-2026-TRF-002', 'TRANSFER', 'FAILED', 1000000.00, 'NGN',
            v_src, v_dst, 'customer:funmilayo',
            'INSUFFICIENT_FUNDS: available_balance 850000.00 < requested 1000000.00',
            NOW() - INTERVAL '22 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO audit_logs (actor, action, entity_type, entity_id, transaction_id, event_details)
    VALUES ('customer:funmilayo', 'TRANSACTION_FAILED', 'TRANSACTION', v_tx::TEXT, v_tx,
            jsonb_build_object('reason', 'INSUFFICIENT_FUNDS', 'attempted_amount', 1000000));
END $seed$;

-- WDR-001: ATM withdrawal (Amaka Current)
DO $seed$
DECLARE v_tx BIGINT; v_src BIGINT; v_settle BIGINT;
BEGIN
    SELECT account_id INTO v_src    FROM accounts WHERE account_number = '1000000002';
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-WDR-001', 'WITHDRAWAL', 'POSTED', 120000.00, 'NGN',
            v_src, v_settle, 'customer:amaka', NOW() - INTERVAL '20 days', NOW() - INTERVAL '20 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src,    'DEBIT',  120000.00, 'NGN', 1, 'ATM Cash Withdrawal: debit Amaka Current'),
           (v_tx, v_settle, 'CREDIT', 120000.00, 'NGN', 2, 'ATM Cash Dispense: credit settlement');
    UPDATE accounts SET available_balance = available_balance - 120000.00 WHERE account_id = v_src;
    INSERT INTO audit_logs (actor, action, entity_type, entity_id, transaction_id, event_details)
    VALUES ('customer:amaka', 'TRANSACTION_POSTED', 'TRANSACTION', v_tx::TEXT, v_tx,
            jsonb_build_object('type', 'ATM_WITHDRAWAL', 'location', 'ATM-LEKKI-01', 'amount_ngn', 120000));
END $seed$;

-- TRF-003: Amaka Savings to Tunde Savings
DO $seed$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '1000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '6000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-TRF-003', 'TRANSFER', 'POSTED', 30000.00, 'NGN',
            v_src, v_dst, 'customer:amaka', NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src, 'DEBIT',  30000.00, 'NGN', 1, 'Transfer out: Amaka Savings'),
           (v_tx, v_dst, 'CREDIT', 30000.00, 'NGN', 2, 'Transfer in: Tunde Savings');
    UPDATE accounts SET available_balance = available_balance - 30000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 30000.00 WHERE account_id = v_dst;
END $seed$;

-- TRF-004: Chukwudi Savings to Ibrahim Current
DO $seed$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '2000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '7000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-TRF-004', 'TRANSFER', 'POSTED', 250000.00, 'NGN',
            v_src, v_dst, 'customer:chukwudi', NOW() - INTERVAL '16 days', NOW() - INTERVAL '16 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src, 'DEBIT',  250000.00, 'NGN', 1, 'Diesel haulage payment: Chukwudi Savings'),
           (v_tx, v_dst, 'CREDIT', 250000.00, 'NGN', 2, 'Freight income: Ibrahim Current');
    UPDATE accounts SET available_balance = available_balance - 250000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 250000.00 WHERE account_id = v_dst;
END $seed$;

-- TRF-005: Tamuno Current to Funmilayo Current
DO $seed$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '9000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '3000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-TRF-005', 'TRANSFER', 'POSTED', 75000.00, 'NGN',
            v_src, v_dst, 'customer:tamuno', NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src, 'DEBIT',  75000.00, 'NGN', 1, 'Tax consulting: Tamuno Current'),
           (v_tx, v_dst, 'CREDIT', 75000.00, 'NGN', 2, 'Professional fee: Funmilayo Current');
    UPDATE accounts SET available_balance = available_balance - 75000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 75000.00 WHERE account_id = v_dst;
END $seed$;

-- TRF-006: Tunde Savings to Osahon Savings
DO $seed$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '6000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '9100000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-TRF-006', 'TRANSFER', 'POSTED', 180000.00, 'NGN',
            v_src, v_dst, 'customer:tunde', NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src, 'DEBIT',  180000.00, 'NGN', 1, 'Building woodwork: Tunde Savings'),
           (v_tx, v_dst, 'CREDIT', 180000.00, 'NGN', 2, 'Craft sales: Osahon Savings');
    UPDATE accounts SET available_balance = available_balance - 180000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 180000.00 WHERE account_id = v_dst;
END $seed$;

-- TRF-007: Zainab Savings to Aisha Current
DO $seed$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '8000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '9200000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-TRF-007', 'TRANSFER', 'POSTED', 65000.00, 'NGN',
            v_src, v_dst, 'customer:zainab', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src, 'DEBIT',  65000.00, 'NGN', 1, 'Hospitality medical: Zainab Savings'),
           (v_tx, v_dst, 'CREDIT', 65000.00, 'NGN', 2, 'Diagnostic fees: Aisha Current');
    UPDATE accounts SET available_balance = available_balance - 65000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 65000.00 WHERE account_id = v_dst;
END $seed$;

-- TRF-008: Babatunde Current to Emeka Savings
DO $seed$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '9300000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '4000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-TRF-008', 'TRANSFER', 'POSTED', 350000.00, 'NGN',
            v_src, v_dst, 'customer:babatunde', NOW() - INTERVAL '8 days', NOW() - INTERVAL '8 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src, 'DEBIT',  350000.00, 'NGN', 1, 'Wholesale grain restocking: Babatunde Current'),
           (v_tx, v_dst, 'CREDIT', 350000.00, 'NGN', 2, 'Agro produce sale: Emeka Savings');
    UPDATE accounts SET available_balance = available_balance - 350000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 350000.00 WHERE account_id = v_dst;
END $seed$;

-- TRF-009: Funmilayo Current to Blessing Savings
DO $seed$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '3000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '5000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-TRF-009', 'TRANSFER', 'POSTED', 20000.00, 'NGN',
            v_src, v_dst, 'customer:funmilayo', NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src, 'DEBIT',  20000.00, 'NGN', 1, 'Fabric payment: Funmilayo Current'),
           (v_tx, v_dst, 'CREDIT', 20000.00, 'NGN', 2, 'Fashion couture sales: Blessing Savings');
    UPDATE accounts SET available_balance = available_balance - 20000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 20000.00 WHERE account_id = v_dst;
END $seed$;

-- REV-002: Reversal of TRF-009
DO $seed$
DECLARE v_orig BIGINT; v_rev BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT transaction_id INTO v_orig FROM transactions WHERE transaction_ref = 'TXN-2026-TRF-009';
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '5000000001'; -- Blessing debited
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '3000000001'; -- Funmilayo credited
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, reversal_of_transaction_id,
        initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-REV-002', 'REVERSAL', 'POSTED', 20000.00, 'NGN',
            v_src, v_dst, v_orig, 'staff:ops02', NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days')
    RETURNING transaction_id INTO v_rev;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_rev, v_src, 'DEBIT',  20000.00, 'NGN', 1, 'Reversal: debit Blessing Savings'),
           (v_rev, v_dst, 'CREDIT', 20000.00, 'NGN', 2, 'Reversal: credit Funmilayo Current');
    UPDATE accounts SET available_balance = available_balance - 20000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 20000.00 WHERE account_id = v_dst;
    INSERT INTO audit_logs (actor, action, entity_type, entity_id, transaction_id, event_details)
    VALUES ('staff:ops02', 'REVERSAL_POSTED', 'TRANSACTION', v_rev::TEXT, v_rev,
            jsonb_build_object('original_ref', 'TXN-2026-TRF-009', 'reason', 'POS duplicate charge resolved with merchant'));
END $seed$;

-- TRF-010: Ibrahim Current to Chukwudi Savings
DO $seed$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '7000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '2000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-TRF-010', 'TRANSFER', 'POSTED', 120000.00, 'NGN',
            v_src, v_dst, 'customer:ibrahim', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src, 'DEBIT',  120000.00, 'NGN', 1, 'Truck maintenance: Ibrahim Current'),
           (v_tx, v_dst, 'CREDIT', 120000.00, 'NGN', 2, 'Motor parts sale: Chukwudi Savings');
    UPDATE accounts SET available_balance = available_balance - 120000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 120000.00 WHERE account_id = v_dst;
END $seed$;

-- TRF-011: Failed transfer (suspended account)
DO $seed$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '5000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '1000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, failure_reason, created_at)
    VALUES ('TXN-2026-TRF-011', 'TRANSFER', 'FAILED', 50000.00, 'NGN',
            v_src, v_dst, 'customer:blessing',
            'CUSTOMER_SUSPENDED: Account debits temporarily restricted pending tier KYC validation',
            NOW() - INTERVAL '4 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO audit_logs (actor, action, entity_type, entity_id, transaction_id, event_details)
    VALUES ('system:policy_engine', 'TRANSACTION_FAILED', 'TRANSACTION', v_tx::TEXT, v_tx,
            jsonb_build_object('reason', 'CUSTOMER_SUSPENDED', 'account_number', '5000000001'));
END $seed$;

-- WDR-002: ATM withdrawal (Tunde Savings)
DO $seed$
DECLARE v_tx BIGINT; v_src BIGINT; v_settle BIGINT;
BEGIN
    SELECT account_id INTO v_src    FROM accounts WHERE account_number = '6000000001';
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-WDR-002', 'WITHDRAWAL', 'POSTED', 80000.00, 'NGN',
            v_src, v_settle, 'customer:tunde', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src,    'DEBIT',  80000.00, 'NGN', 1, 'ATM Cash Withdrawal: debit Tunde Savings'),
           (v_tx, v_settle, 'CREDIT', 80000.00, 'NGN', 2, 'ATM Cash Dispense: credit settlement');
    UPDATE accounts SET available_balance = available_balance - 80000.00 WHERE account_id = v_src;
END $seed$;

-- TRF-012: Tamuno Current to Babatunde Current
DO $seed$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '9000000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '9300000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-TRF-012', 'TRANSFER', 'POSTED', 550000.00, 'NGN',
            v_src, v_dst, 'customer:tamuno', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src, 'DEBIT',  550000.00, 'NGN', 1, 'Offshore catering supplies: Tamuno Current'),
           (v_tx, v_dst, 'CREDIT', 550000.00, 'NGN', 2, 'Commercial retail supplies: Babatunde Current');
    UPDATE accounts SET available_balance = available_balance - 550000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 550000.00 WHERE account_id = v_dst;
END $seed$;

-- TRF-013: Aisha Current to Zainab Savings
DO $seed$
DECLARE v_tx BIGINT; v_src BIGINT; v_dst BIGINT;
BEGIN
    SELECT account_id INTO v_src FROM accounts WHERE account_number = '9200000001';
    SELECT account_id INTO v_dst FROM accounts WHERE account_number = '8000000001';
    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, created_at, posted_at)
    VALUES ('TXN-2026-TRF-013', 'TRANSFER', 'POSTED', 95000.00, 'NGN',
            v_src, v_dst, 'customer:aisha', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day')
    RETURNING transaction_id INTO v_tx;
    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES (v_tx, v_src, 'DEBIT',  95000.00, 'NGN', 1, 'Conference reservation: Aisha Current'),
           (v_tx, v_dst, 'CREDIT', 95000.00, 'NGN', 2, 'Hotel reservation income: Zainab Savings');
    UPDATE accounts SET available_balance = available_balance - 95000.00 WHERE account_id = v_src;
    UPDATE accounts SET available_balance = available_balance + 95000.00 WHERE account_id = v_dst;
END $seed$;

-- 5. Idempotency keys
INSERT INTO idempotency_keys (scope, idem_key, request_hash, transaction_id, created_at)
SELECT 'customer:amaka', 'idem-trx-001',
       md5('TRANSFER|1000000001|2000000001|50000.00|NGN'),
       transaction_id, NOW() - INTERVAL '24 days'
FROM transactions WHERE transaction_ref = 'TXN-2026-TRF-001';

INSERT INTO idempotency_keys (scope, idem_key, request_hash, transaction_id, created_at)
SELECT 'customer:amaka:atm', 'idem-wdr-001',
       md5('WITHDRAWAL|1000000002|120000.00|NGN'),
       transaction_id, NOW() - INTERVAL '20 days'
FROM transactions WHERE transaction_ref = 'TXN-2026-WDR-001';

INSERT INTO idempotency_keys (scope, idem_key, request_hash, transaction_id, created_at)
SELECT 'customer:chukwudi:web', 'idem-trf-004',
       md5('TRANSFER|2000000001|7000000001|250000.00|NGN'),
       transaction_id, NOW() - INTERVAL '16 days'
FROM transactions WHERE transaction_ref = 'TXN-2026-TRF-004';

INSERT INTO idempotency_keys (scope, idem_key, request_hash, transaction_id, created_at)
SELECT 'customer:babatunde:pos', 'idem-trf-008',
       md5('TRANSFER|9300000001|4000000001|350000.00|NGN'),
       transaction_id, NOW() - INTERVAL '8 days'
FROM transactions WHERE transaction_ref = 'TXN-2026-TRF-008';

INSERT INTO idempotency_keys (scope, idem_key, request_hash, transaction_id, created_at)
SELECT 'customer:tamuno:mobile', 'idem-trf-012',
       md5('TRANSFER|9000000001|9300000001|550000.00|NGN'),
       transaction_id, NOW() - INTERVAL '2 days'
FROM transactions WHERE transaction_ref = 'TXN-2026-TRF-012';

-- 6. Balance reconciliation

SELECT
    a.account_number,
    c.full_name,
    a.account_type,
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
GROUP BY a.account_id, a.account_number, c.full_name, a.account_type, a.available_balance
ORDER BY a.account_number;
