-- =============================================================================
-- Portfolio 1: Database Design and Modelling
-- LedgerSpring Digital Bank (LSDB) — Core Schema
-- MIT 8103 Advanced Database Systems
--
-- Run order: 01_create_schema.sql → 02_seed_data.sql → 03_constraint_tests.sql
-- PostgreSQL 15+
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. CUSTOMERS
--    Stores the identity and status of each registered customer.
--    customer_id is a system-generated surrogate key, never exposed externally.
-- ---------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id  BIGINT       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name    TEXT         NOT NULL
                                 CHECK (length(trim(full_name)) > 0),
    -- email and phone are nullable; a customer may register with only one.
    -- Partial unique indexes (below) ensure uniqueness among non-null values.
    email        TEXT         UNIQUE,
    phone        TEXT         UNIQUE,
    status       TEXT         NOT NULL DEFAULT 'ACTIVE'
                                 CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CLOSED')),
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  customers             IS 'Registered LSDB customer profiles.';
COMMENT ON COLUMN customers.customer_id IS 'Surrogate primary key; never reused.';
COMMENT ON COLUMN customers.status      IS 'ACTIVE customers may initiate money movement; SUSPENDED/CLOSED may not.';

-- ---------------------------------------------------------------------------
-- 2. ACCOUNTS
--    Covers both customer-owned accounts and internal system accounts
--    (e.g. the NGN cash-clearing settlement account used to balance
--    deposit and withdrawal ledger entries).
--
--    account_kind distinguishes the two populations:
--      CUSTOMER   — owned by a customer; customer_id is NOT NULL.
--      SETTLEMENT — bank-controlled clearing account; customer_id is NULL.
--      SUSPENSE   — temporary holding account; customer_id is NULL.
--
--    The CHECK constraint enforces this invariant at the database level.
-- ---------------------------------------------------------------------------
CREATE TABLE accounts (
    account_id        BIGINT        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Nullable: system accounts (SETTLEMENT, SUSPENSE) have no customer owner.
    customer_id       BIGINT        REFERENCES customers(customer_id) ON DELETE RESTRICT,
    account_number    VARCHAR(20)   NOT NULL UNIQUE,
    account_kind      TEXT          NOT NULL
                                       CHECK (account_kind IN ('CUSTOMER', 'SETTLEMENT', 'SUSPENSE')),
    -- account_type applies only to CUSTOMER accounts; NULL for system accounts.
    account_type      TEXT          CHECK (account_type IN ('SAVINGS', 'CURRENT')),
    currency          CHAR(3)       NOT NULL DEFAULT 'NGN'
                                       CHECK (currency = 'NGN'),
    -- Cached balance projection for fast reads.
    -- NULL for system accounts whose balance is not tracked as a customer balance.
    available_balance NUMERIC(19,2) CHECK (available_balance >= 0),
    status            TEXT          NOT NULL DEFAULT 'ACTIVE'
                                       CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CLOSED')),
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Invariant: CUSTOMER accounts must have a customer owner and an account_type.
    --            System accounts must NOT have a customer owner or account_type.
    CONSTRAINT chk_account_kind_customer
        CHECK (
            (account_kind = 'CUSTOMER'
                AND customer_id    IS NOT NULL
                AND account_type   IS NOT NULL
                AND available_balance IS NOT NULL)
            OR
            (account_kind IN ('SETTLEMENT', 'SUSPENSE')
                AND customer_id    IS NULL
                AND account_type   IS NULL)
        )
);

COMMENT ON TABLE  accounts                  IS 'Customer and system (clearing/suspense) accounts.';
COMMENT ON COLUMN accounts.account_kind     IS 'CUSTOMER accounts are owned; SETTLEMENT/SUSPENSE are bank-controlled.';
COMMENT ON COLUMN accounts.available_balance IS 'Cached balance for CUSTOMER accounts; kept in sync with ledger entries atomically.';

-- ---------------------------------------------------------------------------
-- 3. TRANSACTIONS
--    Durable record of every money-movement request and its outcome.
--    A transaction has a lifecycle: PENDING → POSTED | FAILED.
--    A POSTED transaction may be linked to a separate reversal transaction
--    via reversal_of_transaction_id (self-referencing FK).
-- ---------------------------------------------------------------------------
CREATE TABLE transactions (
    transaction_id            BIGINT        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Business-facing unique reference (e.g. TXN-20261001-ABCD1234).
    transaction_ref           TEXT          NOT NULL UNIQUE,
    transaction_type          TEXT          NOT NULL
                                               CHECK (transaction_type IN
                                                      ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER', 'REVERSAL')),
    status                    TEXT          NOT NULL DEFAULT 'PENDING'
                                               CHECK (status IN
                                                      ('PENDING', 'POSTED', 'FAILED')),
    -- Positive amount in NGN (exact decimal, never floating-point).
    amount                    NUMERIC(19,2) NOT NULL
                                               CHECK (amount > 0),
    currency                  CHAR(3)       NOT NULL DEFAULT 'NGN'
                                               CHECK (currency = 'NGN'),
    -- For deposits the source_account is the SETTLEMENT account.
    -- For withdrawals the destination_account is the SETTLEMENT account.
    -- Nullable because either side may be a system account that is resolved
    -- at posting time rather than stored redundantly.
    source_account_id         BIGINT        REFERENCES accounts(account_id),
    destination_account_id    BIGINT        REFERENCES accounts(account_id),
    -- Self-referencing FK: populated only when transaction_type = 'REVERSAL'.
    reversal_of_transaction_id BIGINT       REFERENCES transactions(transaction_id),
    -- Actor who initiated the request (customer_id, staff ID, or system label).
    initiated_by              TEXT          NOT NULL,
    failure_reason            TEXT,
    created_at                TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    posted_at                 TIMESTAMPTZ,

    -- A transfer must use different accounts.
    CONSTRAINT chk_transfer_accounts_differ
        CHECK (source_account_id IS NULL
               OR destination_account_id IS NULL
               OR source_account_id <> destination_account_id),

    -- reversal_of_transaction_id is only valid on a REVERSAL transaction.
    CONSTRAINT chk_reversal_type
        CHECK (reversal_of_transaction_id IS NULL
               OR transaction_type = 'REVERSAL'),

    -- At most one full reversal per original transaction.
    -- Enforced by unique index below (allows NULL in non-reversal rows).
    CONSTRAINT uq_one_reversal_per_original
        UNIQUE (reversal_of_transaction_id)
);

COMMENT ON TABLE  transactions                          IS 'Money-movement request records. Financial truth lives in ledger_entries.';
COMMENT ON COLUMN transactions.status                   IS 'PENDING: request received. POSTED: fully committed to ledger. FAILED: rejected.';
COMMENT ON COLUMN transactions.reversal_of_transaction_id IS 'Non-null only for REVERSAL transactions; unique constraint prevents double-reversal.';

-- ---------------------------------------------------------------------------
-- 4. LEDGER_ENTRIES
--    Double-entry journal lines. Every POSTED transaction must have balanced
--    debit and credit entries that sum to the same amount.
--    Entries are immutable once posted; the application role must not be
--    granted UPDATE or DELETE on this table.
-- ---------------------------------------------------------------------------
CREATE TABLE ledger_entries (
    entry_id          BIGINT        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id    BIGINT        NOT NULL
                                       REFERENCES transactions(transaction_id),
    account_id        BIGINT        NOT NULL
                                       REFERENCES accounts(account_id),
    entry_side        TEXT          NOT NULL
                                       CHECK (entry_side IN ('DEBIT', 'CREDIT')),
    amount            NUMERIC(19,2) NOT NULL
                                       CHECK (amount > 0),
    currency          CHAR(3)       NOT NULL DEFAULT 'NGN'
                                       CHECK (currency = 'NGN'),
    -- Sequential line number within the transaction for ordered audit display.
    line_number       SMALLINT      NOT NULL DEFAULT 1
                                       CHECK (line_number > 0),
    description       TEXT,
    entry_timestamp   TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  ledger_entries             IS 'Immutable double-entry journal. Application role may only INSERT, never UPDATE or DELETE.';
COMMENT ON COLUMN ledger_entries.entry_side  IS 'DEBIT reduces the account balance; CREDIT increases it (standard banking convention).';
COMMENT ON COLUMN ledger_entries.line_number IS 'Ordering within one transaction journal.';

-- ---------------------------------------------------------------------------
-- 5. IDEMPOTENCY_KEYS
--    Guards against duplicate financial effects caused by request retries.
--    The scope + key combination is unique. A retry with the same scope/key
--    returns the existing transaction rather than creating a new one.
-- ---------------------------------------------------------------------------
CREATE TABLE idempotency_keys (
    idempotency_id   BIGINT        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Scope identifies the caller/customer context (e.g. customer_id or API client).
    scope            TEXT          NOT NULL,
    idem_key         TEXT          NOT NULL,
    -- Hash of the canonical request payload; used to detect key reuse with a
    -- different payload (which is a conflict, not a retry).
    request_hash     TEXT          NOT NULL,
    -- Resolves to the transaction created by the original request.
    transaction_id   BIGINT        REFERENCES transactions(transaction_id),
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_idempotency_scope_key UNIQUE (scope, idem_key)
);

COMMENT ON TABLE  idempotency_keys              IS 'Prevents duplicate postings from retried requests.';
COMMENT ON COLUMN idempotency_keys.scope        IS 'Namespace for the key; typically the initiating customer_id or service identifier.';
COMMENT ON COLUMN idempotency_keys.request_hash IS 'SHA-256 of the canonical request payload. A scope/key pair with a different hash is a conflict.';

-- ---------------------------------------------------------------------------
-- 6. AUDIT_LOGS
--    Append-only record of significant system and user actions.
--    Must not be used as a substitute for the financial ledger.
--    The application role must only INSERT into this table.
-- ---------------------------------------------------------------------------
CREATE TABLE audit_logs (
    audit_id      BIGINT        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    actor         TEXT          NOT NULL,
    action        TEXT          NOT NULL,
    entity_type   TEXT          NOT NULL,
    entity_id     TEXT,
    -- Optional FK to the triggering transaction; NULL for non-financial events.
    transaction_id BIGINT       REFERENCES transactions(transaction_id),
    -- Structured metadata stored as JSONB for flexible querying.
    -- Must not contain passwords, full card numbers, or BVN.
    event_details JSONB,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE  audit_logs               IS 'Append-only operational/security audit trail. Application role: INSERT only.';
COMMENT ON COLUMN audit_logs.actor         IS 'Identifier of the person or service that performed the action.';
COMMENT ON COLUMN audit_logs.event_details IS 'JSONB metadata. Must exclude sensitive PII, credentials, and raw card data.';

-- =============================================================================
-- INDEXES
-- Chosen to support the queries defined in Portfolio 2.
-- Each index is justified; none is speculative.
-- =============================================================================

-- Customer lookup by email / phone (login / de-duplication checks).
CREATE INDEX idx_customers_email ON customers (lower(email)) WHERE email IS NOT NULL;
CREATE INDEX idx_customers_phone ON customers (phone)       WHERE phone IS NOT NULL;

-- Account lookup by account_number (most common customer-facing key).
CREATE INDEX idx_accounts_account_number ON accounts (account_number);

-- Account history: all accounts for a given customer.
CREATE INDEX idx_accounts_customer_id ON accounts (customer_id) WHERE customer_id IS NOT NULL;

-- Transaction lookup by unique reference (primary operational lookup).
CREATE INDEX idx_transactions_ref ON transactions (transaction_ref);

-- Sender history: all transactions where an account is the source, newest first.
CREATE INDEX idx_transactions_source
    ON transactions (source_account_id, created_at DESC)
    WHERE source_account_id IS NOT NULL;

-- Recipient history: all transactions where an account is the destination.
CREATE INDEX idx_transactions_destination
    ON transactions (destination_account_id, created_at DESC)
    WHERE destination_account_id IS NOT NULL;

-- Operational investigation: find PENDING or FAILED transactions in a time window.
CREATE INDEX idx_transactions_status_time
    ON transactions (status, created_at DESC)
    WHERE status IN ('PENDING', 'FAILED');

-- Ledger lookup by transaction (join from transactions to journal lines).
CREATE INDEX idx_ledger_entries_transaction_id ON ledger_entries (transaction_id);

-- Ledger lookup by account (balance reconciliation queries).
CREATE INDEX idx_ledger_entries_account_id ON ledger_entries (account_id, entry_timestamp DESC);

-- Idempotency key lookup (hot path on every retried request).
-- The unique constraint already creates an index on (scope, idem_key);
-- no additional index is needed.