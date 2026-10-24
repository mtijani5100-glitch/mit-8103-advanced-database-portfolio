# Portfolio 4: NoSQL and Advanced Data Models

**LedgerSpring Digital Bank (LSDB)**  
Student Name: Mubarak Tijani | Student ID: 301915100  
Course: MIT 8103 Advanced Database Systems  
Institution: Miva Open University  

---

## 1. Executive Summary

This portfolio designs, implements, benchmarks, and critically evaluates a document-oriented NoSQL model (**MongoDB**) for LedgerSpring Digital Bank (LSDB), complementing the relational core built in Portfolios 1, 2, and 3.

### Core Architectural Principle
* **PostgreSQL (RDBMS):** The single authoritative system of record for customer accounts, atomic money transfers, and the immutable double-entry ledger.
* **MongoDB (Document Store):** High-throughput, append-only **event stream, audit investigation log, device telemetry, and analytical projection store** (`transaction_events`).

---

## 2. Deliverables Directory Structure

```
portfolio-4-nosql/
├── README.md                                                 # Execution guide and screenshot runbook
├── nosql-model-design.md                                     # JSON Schema, embedding vs referencing, index design
├── sql-vs-nosql-rationale.md                                 # CAP theorem, authoritative balance vs event projection, outbox pattern
├── data/
│   └── Tijani_Mubarak_301915100_P4_Events_Seed.json          # 20 synthetic Nigerian fintech transaction events
├── scripts/
│   ├── Tijani_Mubarak_301915100_P4_01_SetupCollection.js     # MongoDB schema validator & index creation script
│   ├── Tijani_Mubarak_301915100_P4_02_SeedEvents.js          # Ingestion script for 20 BSON transaction events
│   ├── Tijani_Mubarak_301915100_P4_03_QueriesAndAggregations.js # Queries (Q1-Q3) and Aggregation Pipelines (Agg1-Agg3)
│   ├── Tijani_Mubarak_301915100_P4_04_OutboxPattern.js       # Transactional outbox idempotent consumer demonstration
│   └── Tijani_Mubarak_301915100_P4_RunLab.js                 # Standalone Node.js execution engine (instant terminal testing)
└── evidence/
    └── (Evidence screenshots prefixed with Tijani_Mubarak_301915100_P4_...)
```

---

## 3. How to Run the Portfolio 4 Lab

You have **two execution options**:

### Option A: Standalone Node.js Execution Engine (Instant, Zero Dependencies)
Run the automated runner directly from the terminal. It evaluates schema validations, executes queries with formatted console tables, runs all aggregations, and tests the outbox pattern:

```bash
node portfolio-4-nosql/scripts/Tijani_Mubarak_301915100_P4_RunLab.js
```

### Option B: Native MongoDB (`mongosh` or MongoDB Compass)
If running a local MongoDB instance (`mongodb-community`) or MongoDB Atlas cluster:

```bash
# 1. Connect and create schema with validation & indexes
mongosh lsdb_events portfolio-4-nosql/scripts/Tijani_Mubarak_301915100_P4_01_SetupCollection.js

# 2. Ingest the 20 Nigerian banking event documents
mongosh lsdb_events portfolio-4-nosql/scripts/Tijani_Mubarak_301915100_P4_02_SeedEvents.js

# 3. Execute queries and analytical aggregation pipelines
mongosh lsdb_events portfolio-4-nosql/scripts/Tijani_Mubarak_301915100_P4_03_QueriesAndAggregations.js

# 4. Demonstrate transactional outbox idempotent ingestion
mongosh lsdb_events portfolio-4-nosql/scripts/Tijani_Mubarak_301915100_P4_04_OutboxPattern.js
```

---

## 4. Evidence to Capture for Submission

Capture clean screenshots of the execution outputs and save them into `portfolio-4-nosql/evidence/` with the exact student prefix:

| Screenshot Filename | Target Component | Description / Proof |
|---|---|---|
| `Tijani_Mubarak_301915100_P4_01_Schema_and_Indexes.png` | Script 01 / Setup | Creation of `transaction_events` with `$jsonSchema` and all 5 strategic indexes |
| `Tijani_Mubarak_301915100_P4_02_Seed_Documents_Ingested.png` | Script 02 / Seed | Successful ingestion of all 20 BSON event documents |
| `Tijani_Mubarak_301915100_P4_03_Query_Customer_Activity.png` | Query 1 | Reverse-chronological customer activity feed using `idx_customer_timeline` |
| `Tijani_Mubarak_301915100_P4_04_Query_Lifecycle_Lookup.png` | Query 2 | Point lookup by `transaction_ref` showing complete lifecycle progression |
| `Tijani_Mubarak_301915100_P4_05_Query_Failed_Diagnostics.png` | Query 3 | Operational diagnostic filter for failed transfers showing error codes |
| `Tijani_Mubarak_301915100_P4_06_Agg_Failure_Distribution.png` | Aggregation 1 | Aggregation pipeline grouping failed volume by reason and channel |
| `Tijani_Mubarak_301915100_P4_07_Agg_Channel_Turnover.png` | Aggregation 2 | Multi-channel volume, total turnover, and average latency breakdown |
| `Tijani_Mubarak_301915100_P4_08_Agg_Fraud_Security.png` | Aggregation 3 | Fraud detection flagging risk scores >= 0.70 and impossible travel |
| `Tijani_Mubarak_301915100_P4_09_Outbox_Idempotent_Replay.png` | Script 04 / Outbox | Proof of idempotent deduplication: replayed event results in `upsertedCount: 0` |

---

## 5. Architectural Summaries

* See [`nosql-model-design.md`](./nosql-model-design.md) for complete JSON schema specifications, embedding vs referencing analysis, and anti-pattern avoidance notes.
* See [`sql-vs-nosql-rationale.md`](./sql-vs-nosql-rationale.md) for in-depth CAP theorem trade-offs, authoritative balance separation, and the Transactional Outbox Pattern architecture.
