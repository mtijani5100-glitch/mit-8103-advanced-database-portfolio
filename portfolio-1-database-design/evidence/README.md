# Portfolio 1: Database Design and Modelling
## LedgerSpring Digital Bank (LSDB)

**MIT 8103 Advanced Database Systems**

---

## Quick Start

```bash
# 1. Create the database
createdb lsdb_dev

# 2. Build the schema (all six tables + indexes)
psql -d lsdb_dev -f sql/Tijani_Mubarak_301915100_P1_CreateSchema.sql

# 3. Load synthetic seed data
psql -d lsdb_dev -f sql/Tijani_Mubarak_301915100_P1_SeedData.sql

# 4. Run constraint tests (all should PASS)
psql -d lsdb_dev -f sql/Tijani_Mubarak_301915100_P1_ConstraintTests.sql
```

---

## Portfolio Evidence

| File | Purpose |
|---|---|
| [`sql/Tijani_Mubarak_301915100_P1_CreateSchema.sql`](sql/Tijani_Mubarak_301915100_P1_CreateSchema.sql) | DDL for all six core tables, constraints, and indexes |
| [`sql/Tijani_Mubarak_301915100_P1_SeedData.sql`](sql/Tijani_Mubarak_301915100_P1_SeedData.sql) | Synthetic data: 6 customers, 10 accounts, 7 transactions, ledger entries |
| [`sql/Tijani_Mubarak_301915100_P1_ConstraintTests.sql`](sql/Tijani_Mubarak_301915100_P1_ConstraintTests.sql) | 11 named tests demonstrating database rule enforcement |
| [`relational-schema.md`](relational-schema.md) | Full data dictionary with column types, keys, and FK map |
| [`normalisation.md`](normalisation.md) | 1NF → BCNF analysis tied to the actual schema |
| [`../docs/decisions/case-study.md`](../docs/decisions/case-study.md) | Case study description |
| [`../docs/business-rules.md`](../docs/business-rules.md) | 29 numbered business rules |
| [`../diagrams/Tijani_Mubarak_301915100_ERD_v2.drawio`](../diagrams/Tijani_Mubarak_301915100_ERD_v2.drawio) | Editable ERD source (diagrams.net) |
| [`evidence/`](evidence/) | Screenshots and query outputs |

---

## Entities

| Table | Purpose |
|---|---|
| `customers` | Customer identity and status |
| `accounts` | Customer and system clearing/suspense accounts |
| `transactions` | Money-movement request records |
| `ledger_entries` | Double-entry journal lines (immutable) |
| `idempotency_keys` | Retry-safe deduplication guard |
| `audit_logs` | Append-only operational audit trail |

---

## Key Design Decisions

1. **System accounts are nullable-owner `accounts` rows**, distinguished by
   `account_kind = 'SETTLEMENT'`. This allows deposits and withdrawals to
   post balanced ledger entries without a separate "clearing" table.

2. **`available_balance` is a cached projection**, deliberately denormalised
   for read performance. It is always updated atomically with ledger entries
   in the same `BEGIN`/`COMMIT` block. A reconciliation query verifies it.

3. **One full reversal per original transaction** is enforced by a `UNIQUE`
   constraint on `transactions.reversal_of_transaction_id`, preventing
   concurrent double-reversal races.

4. **`ledger_entries` is immutable**: no `UPDATE` or `DELETE` is permitted
   for the application role. Corrections are made by a compensating reversal
   transaction.
