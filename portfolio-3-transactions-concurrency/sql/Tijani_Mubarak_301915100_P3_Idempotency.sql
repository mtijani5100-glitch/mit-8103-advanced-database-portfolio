-- Portfolio 3: Transactions and Concurrency
-- Idempotency and duplicate prevention demonstrations
-- Mubarak Tijani (301915100)

-- Initial transfer submission with idempotency key
DO $$
DECLARE
    v_tx         BIGINT;
    v_idem       BIGINT;
    v_alice      BIGINT;
    v_bob        BIGINT;
    v_scope      CONSTANT TEXT := 'p3:alice';
    v_idem_key   CONSTANT TEXT := 'P3-IDEM-KEY-001';
    v_req_hash   CONSTANT TEXT := md5('alice-to-bob-50000.00');
    v_amount     CONSTANT NUMERIC := 50000.00;
BEGIN
    SELECT account_id INTO v_alice FROM accounts WHERE account_number = 'P3-ALICE-001';
    SELECT account_id INTO v_bob   FROM accounts WHERE account_number = 'P3-BOB-001';

    -- Check if request key was already resolved
    SELECT idempotency_id, transaction_id
    INTO   v_idem, v_tx
    FROM   idempotency_keys
    WHERE  scope = v_scope AND idem_key = v_idem_key;

    IF FOUND THEN
        RAISE NOTICE 'Key already processed (tx: %). Returning cached result.', v_tx;
        RETURN;
    END IF;

    -- Lock accounts in deterministic order
    PERFORM account_id FROM accounts WHERE account_id = LEAST(v_alice, v_bob)    FOR UPDATE;
    PERFORM account_id FROM accounts WHERE account_id = GREATEST(v_alice, v_bob) FOR UPDATE;

    IF (SELECT available_balance FROM accounts WHERE account_id = v_alice) < v_amount THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;

    INSERT INTO transactions (transaction_ref, transaction_type, status, amount, currency,
        source_account_id, destination_account_id, initiated_by, posted_at)
    VALUES ('TXN-P3-IDEM-001', 'TRANSFER', 'POSTED', v_amount, 'NGN',
            v_alice, v_bob, v_scope, NOW())
    RETURNING transaction_id INTO v_tx;

    INSERT INTO ledger_entries (transaction_id, account_id, entry_side, amount, currency, line_number, description)
    VALUES
        (v_tx, v_alice, 'DEBIT',  v_amount, 'NGN', 1, 'Idempotent transfer: Alice out'),
        (v_tx, v_bob,   'CREDIT', v_amount, 'NGN', 2, 'Idempotent transfer: Bob in');

    UPDATE accounts SET available_balance = available_balance - v_amount WHERE account_id = v_alice;
    UPDATE accounts SET available_balance = available_balance + v_amount WHERE account_id = v_bob;

    -- Store idempotency record for client deduplication
    INSERT INTO idempotency_keys (scope, idem_key, request_hash, transaction_id)
    VALUES (v_scope, v_idem_key, v_req_hash, v_tx);

    RAISE NOTICE 'Initial submission posted: transaction_id = %', v_tx;
END $$;

-- Simulated client retry: same key, same payload (network timeout recovery)
DO $$
DECLARE
    v_idem_key CONSTANT TEXT := 'P3-IDEM-KEY-001';
    v_scope    CONSTANT TEXT := 'p3:alice';
    v_tx       BIGINT;
BEGIN
    SELECT transaction_id INTO v_tx
    FROM   idempotency_keys
    WHERE  scope = v_scope AND idem_key = v_idem_key;

    IF FOUND THEN
        RAISE NOTICE 'Duplicate request detected: key % resolved to existing transaction_id = %. No financial posting created.', v_idem_key, v_tx;
    ELSE
        RAISE EXCEPTION 'Idempotency lookup failed unexpectedly';
    END IF;
END $$;

-- Verify only 1 transaction record exists for this idempotency key
SELECT COUNT(*) AS posting_count
FROM transactions t
JOIN idempotency_keys ik ON ik.transaction_id = t.transaction_id
WHERE ik.idem_key = 'P3-IDEM-KEY-001'
  AND t.status = 'POSTED';

-- Conflict test: same idempotency key submitted with different payload
DO $$
DECLARE
    v_idem_key    CONSTANT TEXT := 'P3-IDEM-KEY-001';
    v_scope       CONSTANT TEXT := 'p3:alice';
    v_new_hash    CONSTANT TEXT := md5('alice-to-bob-99999.00');
    v_stored_hash TEXT;
BEGIN
    SELECT request_hash INTO v_stored_hash
    FROM   idempotency_keys
    WHERE  scope = v_scope AND idem_key = v_idem_key;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Idempotency key not found';
    END IF;

    IF v_stored_hash <> v_new_hash THEN
        RAISE NOTICE 'Payload mismatch: key % already bound to hash %, submitted %. Request rejected with 409 Conflict.',
                     v_idem_key, v_stored_hash, v_new_hash;
    ELSE
        RAISE NOTICE 'Payload matches existing record';
    END IF;
END $$;

-- Verify balances reflect exactly one 50,000 NGN transfer
SELECT account_number, full_name, available_balance AS final_balance
FROM accounts a JOIN customers c USING (customer_id)
WHERE a.account_number IN ('P3-ALICE-001', 'P3-BOB-001')
ORDER BY account_number;
