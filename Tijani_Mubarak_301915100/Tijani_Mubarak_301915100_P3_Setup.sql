-- Portfolio 3: Transactions and Concurrency
-- Setup script: test customers, accounts, and opening funding
-- Mubarak Tijani (301915100)

-- Test customer profiles
INSERT INTO customers (full_name, email, phone, status)
VALUES
    ('P3 Demo Alice',   'p3.alice@lsdb-demo.ng',   '09099910001', 'ACTIVE'),
    ('P3 Demo Bob',     'p3.bob@lsdb-demo.ng',     '09099910002', 'ACTIVE'),
    ('P3 Demo Charlie', 'p3.charlie@lsdb-demo.ng', '09099910003', 'ACTIVE')
ON CONFLICT DO NOTHING;

-- Test accounts for transfer, race, and deadlock scenarios
INSERT INTO accounts (customer_id, account_number, account_kind, account_type, currency, available_balance, status)
SELECT customer_id, 'P3-ALICE-001', 'CUSTOMER', 'SAVINGS', 'NGN', 0.00, 'ACTIVE'
FROM customers WHERE email = 'p3.alice@lsdb-demo.ng'
ON CONFLICT DO NOTHING;

INSERT INTO accounts (customer_id, account_number, account_kind, account_type, currency, available_balance, status)
SELECT customer_id, 'P3-BOB-001', 'CUSTOMER', 'CURRENT', 'NGN', 0.00, 'ACTIVE'
FROM customers WHERE email = 'p3.bob@lsdb-demo.ng'
ON CONFLICT DO NOTHING;

INSERT INTO accounts (customer_id, account_number, account_kind, account_type, currency, available_balance, status)
SELECT customer_id, 'P3-CHARLIE-001', 'CUSTOMER', 'SAVINGS', 'NGN', 0.00, 'ACTIVE'
FROM customers WHERE email = 'p3.charlie@lsdb-demo.ng'
ON CONFLICT DO NOTHING;

-- Fund Alice: 500,000 NGN via central settlement
DO $$
DECLARE
    v_tx     BIGINT;
    v_settle BIGINT;
    v_alice  BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_alice  FROM accounts WHERE account_number = 'P3-ALICE-001';

    IF EXISTS (SELECT 1 FROM transactions WHERE transaction_ref = 'TXN-P3-FUND-ALICE') THEN
        RETURN;
    END IF;

    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, posted_at)
    VALUES ('TXN-P3-FUND-ALICE', 'DEPOSIT', 'POSTED', 500000.00, 'NGN',
            v_settle, v_alice, 'p3:setup', NOW())
    RETURNING transaction_id INTO v_tx;

    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES
        (v_tx, v_settle, 'DEBIT',  500000.00, 'NGN', 1, 'Settlement debit: fund P3 Alice'),
        (v_tx, v_alice,  'CREDIT', 500000.00, 'NGN', 2, 'Opening credit: P3 Alice demo account');

    UPDATE accounts SET available_balance = available_balance + 500000.00 WHERE account_id = v_alice;
END $$;

-- Fund Bob: 200,000 NGN
DO $$
DECLARE
    v_tx     BIGINT;
    v_settle BIGINT;
    v_bob    BIGINT;
BEGIN
    SELECT account_id INTO v_settle FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_bob    FROM accounts WHERE account_number = 'P3-BOB-001';

    IF EXISTS (SELECT 1 FROM transactions WHERE transaction_ref = 'TXN-P3-FUND-BOB') THEN
        RETURN;
    END IF;

    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, posted_at)
    VALUES ('TXN-P3-FUND-BOB', 'DEPOSIT', 'POSTED', 200000.00, 'NGN',
            v_settle, v_bob, 'p3:setup', NOW())
    RETURNING transaction_id INTO v_tx;

    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES
        (v_tx, v_settle, 'DEBIT',  200000.00, 'NGN', 1, 'Settlement debit: fund P3 Bob'),
        (v_tx, v_bob,    'CREDIT', 200000.00, 'NGN', 2, 'Opening credit: P3 Bob demo account');

    UPDATE accounts SET available_balance = available_balance + 200000.00 WHERE account_id = v_bob;
END $$;

-- Fund Charlie: 300,000 NGN
DO $$
DECLARE
    v_tx      BIGINT;
    v_settle  BIGINT;
    v_charlie BIGINT;
BEGIN
    SELECT account_id INTO v_settle  FROM accounts WHERE account_number = 'SYS0000001';
    SELECT account_id INTO v_charlie FROM accounts WHERE account_number = 'P3-CHARLIE-001';

    IF EXISTS (SELECT 1 FROM transactions WHERE transaction_ref = 'TXN-P3-FUND-CHARLIE') THEN
        RETURN;
    END IF;

    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, posted_at)
    VALUES ('TXN-P3-FUND-CHARLIE', 'DEPOSIT', 'POSTED', 300000.00, 'NGN',
            v_settle, v_charlie, 'p3:setup', NOW())
    RETURNING transaction_id INTO v_tx;

    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES
        (v_tx, v_settle,  'DEBIT',  300000.00, 'NGN', 1, 'Settlement debit: fund P3 Charlie'),
        (v_tx, v_charlie, 'CREDIT', 300000.00, 'NGN', 2, 'Opening credit: P3 Charlie demo account');

    UPDATE accounts SET available_balance = available_balance + 300000.00 WHERE account_id = v_charlie;
END $$;

-- Verify baseline balances
SELECT
    a.account_number,
    c.full_name,
    a.account_kind,
    a.status                      AS account_status,
    a.available_balance           AS balance_ngn,
    a.available_balance * 100     AS balance_kobo
FROM accounts a
JOIN customers c ON c.customer_id = a.customer_id
WHERE a.account_number LIKE 'P3-%'
ORDER BY a.account_number;
