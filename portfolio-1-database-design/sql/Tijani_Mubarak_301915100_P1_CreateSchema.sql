-- Core schema for LedgerSpring Digital Bank (LSDB)

CREATE TABLE customers (
    customer_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name    TEXT NOT NULL CHECK (length(trim(full_name)) > 0),
    email        TEXT UNIQUE,
    phone        TEXT UNIQUE,
    status       TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CLOSED')),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE accounts (
    account_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id       BIGINT REFERENCES customers(customer_id) ON DELETE RESTRICT,
    account_number    VARCHAR(20) NOT NULL UNIQUE,
    account_kind      TEXT NOT NULL CHECK (account_kind IN ('CUSTOMER', 'SETTLEMENT', 'SUSPENSE')),
    account_type      TEXT CHECK (account_type IN ('SAVINGS', 'CURRENT')),
    currency          CHAR(3) NOT NULL DEFAULT 'NGN' CHECK (currency = 'NGN'),
    available_balance NUMERIC(19, 2) CHECK (available_balance >= 0),
    status            TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CLOSED')),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Customer accounts require an owner and non-null balance; system accounts do not
    CONSTRAINT chk_account_kind_customer CHECK (
        (account_kind = 'CUSTOMER'
            AND customer_id IS NOT NULL
            AND account_type IS NOT NULL
            AND available_balance IS NOT NULL)
        OR
        (account_kind IN ('SETTLEMENT', 'SUSPENSE')
            AND customer_id IS NULL
            AND account_type IS NULL)
    )
);

CREATE TABLE transactions (
    transaction_id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_ref            TEXT NOT NULL UNIQUE,
    transaction_type           TEXT NOT NULL CHECK (transaction_type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER', 'REVERSAL')),
    status                     TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'POSTED', 'FAILED')),
    amount                     NUMERIC(19, 2) NOT NULL CHECK (amount > 0),
    currency                   CHAR(3) NOT NULL DEFAULT 'NGN' CHECK (currency = 'NGN'),
    source_account_id          BIGINT REFERENCES accounts(account_id),
    destination_account_id     BIGINT REFERENCES accounts(account_id),
    reversal_of_transaction_id BIGINT REFERENCES transactions(transaction_id),
    initiated_by               TEXT NOT NULL,
    failure_reason             TEXT,
    created_at                 TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    posted_at                  TIMESTAMPTZ,

    CONSTRAINT chk_transfer_accounts_differ CHECK (
        source_account_id IS NULL
        OR destination_account_id IS NULL
        OR source_account_id <> destination_account_id
    ),

    CONSTRAINT chk_reversal_type CHECK (
        reversal_of_transaction_id IS NULL
        OR transaction_type = 'REVERSAL'
    ),

    -- Allow at most one reversal per original transaction
    CONSTRAINT uq_one_reversal_per_original UNIQUE (reversal_of_transaction_id)
);

-- Immutable double-entry ledger journal
CREATE TABLE ledger_entries (
    entry_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id  BIGINT NOT NULL REFERENCES transactions(transaction_id),
    account_id      BIGINT NOT NULL REFERENCES accounts(account_id),
    entry_side      TEXT NOT NULL CHECK (entry_side IN ('DEBIT', 'CREDIT')),
    amount          NUMERIC(19, 2) NOT NULL CHECK (amount > 0),
    currency        CHAR(3) NOT NULL DEFAULT 'NGN' CHECK (currency = 'NGN'),
    line_number     SMALLINT NOT NULL DEFAULT 1 CHECK (line_number > 0),
    description     TEXT,
    entry_timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE idempotency_keys (
    idempotency_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    scope          TEXT NOT NULL,
    idem_key       TEXT NOT NULL,
    request_hash   TEXT NOT NULL,
    transaction_id BIGINT REFERENCES transactions(transaction_id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_idempotency_scope_key UNIQUE (scope, idem_key)
);

CREATE TABLE audit_logs (
    audit_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actor          TEXT NOT NULL,
    action         TEXT NOT NULL,
    entity_type    TEXT NOT NULL,
    entity_id      TEXT,
    transaction_id BIGINT REFERENCES transactions(transaction_id),
    event_details  JSONB,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for frequent lookup paths
CREATE INDEX idx_customers_email ON customers (lower(email)) WHERE email IS NOT NULL;
CREATE INDEX idx_customers_phone ON customers (phone) WHERE phone IS NOT NULL;

CREATE INDEX idx_accounts_account_number ON accounts (account_number);
CREATE INDEX idx_accounts_customer_id ON accounts (customer_id) WHERE customer_id IS NOT NULL;

CREATE INDEX idx_transactions_ref ON transactions (transaction_ref);
CREATE INDEX idx_transactions_source ON transactions (source_account_id, created_at DESC) WHERE source_account_id IS NOT NULL;
CREATE INDEX idx_transactions_destination ON transactions (destination_account_id, created_at DESC) WHERE destination_account_id IS NOT NULL;
CREATE INDEX idx_transactions_status_time ON transactions (status, created_at DESC) WHERE status IN ('PENDING', 'FAILED');

CREATE INDEX idx_ledger_entries_transaction_id ON ledger_entries (transaction_id);
CREATE INDEX idx_ledger_entries_account_id ON ledger_entries (account_id, entry_timestamp DESC);