# Portfolio 1: Case Study Context — LedgerSpring Digital Bank (LSDB)

> **Course:** MIT 8103 Advanced Database Systems  
> **Component:** Portfolio 1 — Database Design and Modelling  
> **Master Reference:** See detailed organizational definition in [docs/decisions/case-study.md](file:///Users/tijanimubarak/Developer/mit-8103-advanced-database-portfolio/docs/decisions/case-study.md) and business rules in [docs/business-rules.md](file:///Users/tijanimubarak/Developer/mit-8103-advanced-database-portfolio/docs/business-rules.md).

---

## 1. Executive Summary

**LedgerSpring Digital Bank (LSDB)** is a fictional Nigerian digital banking platform designed specifically as an academic case study for MIT 8103. The platform provides personal banking services, including savings and current accounts, fund transfers, simulated deposits and withdrawals, transaction reversals, idempotency guards, and immutable double-entry financial accounting.

All records, identities, and transaction histories in this database are synthetic.

---

## 2. Core Stakeholders and Actors

| Role | Responsibilities within Database |
|---|---|
| **Retail Customers** | Own one or more active accounts; initiate internal transfers and withdrawals. |
| **Operations Staff** | Monitor operational queues, investigate transaction failures, and execute audited compensating reversals. |
| **Compliance & Internal Audit** | Inspect append-only audit event logs and run periodic double-entry reconciliation queries. |
| **System / Application Role** | Execute atomic posting transactions, write balanced ledger journal entries, and update cached balances. |

---

## 3. Scope of Portfolio 1 Data Model

The relational schema implements 6 core entities in PostgreSQL:

1. **`customers`**: Customer profiles, KYC tiering, registration timestamps, and account status.
2. **`accounts`**: Customer-facing accounts (Savings, Current) and bank-controlled internal clearing accounts (`SETTLEMENT`, `SUSPENSE`).
3. **`transactions`**: Durable request records capturing lifecycle status (`PENDING`, `POSTED`, `FAILED`), amounts, and self-referencing reversal links.
4. **`ledger_entries`**: Append-only, double-entry financial journal lines (Debit / Credit) where total debits must equal total credits.
5. **`idempotency_keys`**: Cryptographic request hash store to guarantee at-most-once execution for financial operations.
6. **`audit_logs`**: Append-only operational event log capturing actor, entity, action, and JSONB contextual metadata.

---

## 4. Key Financial and Modelling Invariants

- **Exact Monetary Representation:** Stored as `NUMERIC(19, 2)` (or integer kobo) with explicit `CHECK (amount > 0)`. Floating-point types are strictly forbidden.
- **Double-Entry Ledger Invariant:** Every posted transaction has balanced debit and credit entries in `ledger_entries`.
- **Derived Cached Balances:** `accounts.available_balance` is an intentional denormalisation for performant balance checks. The authoritative source of truth is the ledger journal (`reconciliation query` verifies parity).
- **Compensating Reversals:** Transactions are never deleted or modified. Reversals create new compensating ledger entries linked via a unique foreign key `reversal_of_transaction_id` to prevent duplicate reversals.
- **Strict Account Polymorphism:** A `CHECK` constraint enforces that `CUSTOMER` accounts must have a non-null `customer_id` and `available_balance`, whereas internal `SETTLEMENT` / `SUSPENSE` accounts must not have a `customer_id`.

---

## 5. Directory References

- **Full Data Dictionary & Mermaid Schema:** [evidence/relational-schema.md](file:///Users/tijanimubarak/Developer/mit-8103-advanced-database-portfolio/portfolio-1-database-design/evidence/relational-schema.md)
- **Normalisation Analysis (1NF to BCNF):** [evidence/normalisation.md](file:///Users/tijanimubarak/Developer/mit-8103-advanced-database-portfolio/portfolio-1-database-design/evidence/normalisation.md)
- **Executable DDL:** [sql/01_create_schema.sql](file:///Users/tijanimubarak/Developer/mit-8103-advanced-database-portfolio/portfolio-1-database-design/sql/01_create_schema.sql)
- **Synthetic Seed Data:** [sql/02_seed_data.sql](file:///Users/tijanimubarak/Developer/mit-8103-advanced-database-portfolio/portfolio-1-database-design/sql/02_seed_data.sql)
- **Constraint Test Suite:** [sql/03_constraint_tests.sql](file:///Users/tijanimubarak/Developer/mit-8103-advanced-database-portfolio/portfolio-1-database-design/sql/03_constraint_tests.sql)
