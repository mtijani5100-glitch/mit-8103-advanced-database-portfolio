# Portfolio 4: SQL vs. NoSQL Architectural Rationale
## LedgerSpring Digital Bank (LSDB) | Mubarak Tijani (ID: 301915100)

---

## 1. Executive Summary

Financial core banking platforms operate under demanding safety invariants: accounts must not overdraw beyond credit terms, transfers must debit sender and credit receiver atomically, and every balance change must reconcile mathematically against an immutable ledger journal.

This analysis evaluates why **PostgreSQL** remains the authoritative system of record for accounting invariants, while **MongoDB** serves as an event store and analytical projection engine.

---

## 2. Comparative Matrix: PostgreSQL vs. MongoDB

| Dimension | PostgreSQL (RDBMS) | MongoDB (Document Store) | LSDB Architectural Role |
|---|---|---|---|
| **Data Model** | Relational tables, strict schemas, foreign keys, check constraints | Flexible JSON/BSON documents, dynamic schema, embedded objects | **PostgreSQL:** Authoritative ledger & accounts<br>**MongoDB:** Polymorphic event streams |
| **Transaction Model** | Full ACID (Multi-Version Concurrency Control, row-level locks) | Multi-document ACID within replica sets (higher latency/coordination) | **PostgreSQL:** Immediate atomic debit/credit balance mutation |
| **Integrity Enforcement** | Database-level foreign keys, unique indexes, `CHECK (balance >= 0)` | Schema validation rules (`$jsonSchema`), application-level constraints | **PostgreSQL:** Financial rules enforced at engine level |
| **Query Strengths** | Complex relational joins, window functions, strict financial rollups | Hierarchical document filtering, dynamic projection, pipeline aggregations | **MongoDB:** Multi-channel telemetry, audit search, fraud analytics |
| **Scalability Model** | Vertical scaling for writes; read replicas for horizontal reads | Horizontal sharding by shard key across commodity nodes | **PostgreSQL:** Primary-replica topology<br>**MongoDB:** Sharded event cluster |
| **Consistency Guarantee** | Immediate Strong Consistency | Configurable (Read Concern: `linearizable`, `majority`, `local`) | **PostgreSQL:** CP under partition<br>**MongoDB:** Eventual projection |

---

## 3. Authoritative Balance vs. Event Projections

### 3.1 Why MongoDB Must NOT Store the Authoritative Balance
In banking systems, treating a document store as the authoritative balance engine presents catastrophic failure modes:

1. **Lost Updates Under High Concurrency:** If two transfers read a customer document, evaluate spendable funds, and decrement a document balance, concurrent updates can overwrite each other unless distributed lock managers or heavy OCC (Optimistic Concurrency Control) loops are introduced.
2. **Double-Entry Journal Integrity:** In PostgreSQL, relational foreign keys and check constraints guarantee that every transaction produces exactly two balanced ledger entries (DEBIT and CREDIT) and updates account rows in the same transaction block. In a document model, modeling bilateral ledger entries across separate account documents requires multi-document transactions that incur significant performance penalties across distributed shards.
3. **Audit Immutability:** PostgreSQL table triggers and append-only constraints protect financial history from accidental in-place mutation. Document stores typically encourage document replacement, which increases the risk of inadvertent history erasure.

### 3.2 Why MongoDB Excels for Event Projections
While relational databases excel at ledger math, they struggle with high-volume, unstructured event telemetry:

* **Channel Heterogeneity:** A USSD transfer contains cell tower identifiers and session timeouts; a web transfer contains browser user-agents and TLS fingerprints; an NIP transfer contains interbank switch session identifiers. Forcing this polymorphic metadata into relational columns produces wide, sparse tables with dozens of nullable fields. MongoDB absorbs this polymorphism naturally.
* **Write Throughput for Audit Telemetry:** High-frequency event streams (login attempts, device changes, push notification delivery, biometric authentications) can overwhelm relational write queues. MongoDB easily ingests append-only JSON streams.
* **Complex Analytical Aggregations:** Aggregating transaction failures by device model, operating system, and interbank clearing codes is easily handled via MongoDB's Aggregation Pipeline (`$match`, `$group`, `$facet`) without competing with core banking OLTP queries for database buffers.

---

## 4. CAP Theorem & PACELC Analysis

Under Eric Brewer's CAP theorem (Consistency, Availability, Partition Tolerance):

```
         PostgreSQL (Core Banking)           MongoDB (Event Stream)
                     CP                                 AP / Tunable
        ┌─────────────────────────┐        ┌─────────────────────────┐
        │ Focus: Strong Immediate │        │ Focus: High Ingestion   │
        │ Consistency over local  │        │ Throughput, Read Scale, │
        │ availability during     │        │ Eventual Consistency    │
        │ network partitions.     │        │ across analytical nodes │
        └─────────────────────────┘        └─────────────────────────┘
```

* **PostgreSQL (CP):** If a network partition isolates the primary database node, incoming financial transfers fail rather than risk split-brain balance divergence or double-spending.
* **MongoDB (Tunable / AP for Reads):** Customer timeline queries and fraud detection dashboards read from secondary replicas using `readPreference: "secondaryPreferred"`. If replication lags behind the primary node by 150 ms, the customer sees their recent transfer appear a fraction of a second later in their activity feed, but the bank's core ledger remains correct.

### PACELC Perspective
* If there is a **Partition (P)**, trade **Availability (A)** for **Consistency (C)** on financial mutations.
* **Else (E)**, when running normally, trade **Latency (L)** for **Consistency (C)** on balance updates, but trade **Consistency (C)** for **Latency (L)** on customer telemetry.

---

## 5. The Dual-Write Problem and the Transactional Outbox Pattern

### 5.1 The Anti-Pattern: Direct Dual Writing
A common anti-pattern in distributed architectures is having the application service write to PostgreSQL and MongoDB sequentially:

```
[Client] --> [API Service] ──(1) Write to PostgreSQL (COMMIT)──> [PostgreSQL]
                   │
                   └──(2) Write to MongoDB (CRASH / TIMEOUT)──> [MongoDB] (LOST!)
```

If the API service crashes or encounters a network partition after step (1) commits, PostgreSQL records the transfer, but MongoDB never receives the event. The two databases diverge permanently.

### 5.2 The Robust Solution: Transactional Outbox Pattern
LSDB implements the Transactional Outbox Pattern:

```
[Client] --> [API Service]
                   │
                   ▼ (Single Atomic ACID Transaction)
      ┌────────────────────────────────────────────────────────┐
      │  PostgreSQL Primary Database                           │
      │  1. Insert into transactions                           │
      │  2. Insert into ledger_entries (DEBIT & CREDIT)        │
      │  3. Update accounts (available_balance)                │
      │  4. Insert into outbox_events (status = 'UNPUBLISHED') │
      │  5. COMMIT                                             │
      └────────────────────────────────────────────────────────┘
                   │
                   ▼
      [Asynchronous Event Dispatcher / Debezium CDC]
                   │
                   ├─► Reads UNPUBLISHED outbox events
                   ├─► Idempotently upserts into MongoDB (event_id)
                   └─► Marks outbox event PUBLISHED in PostgreSQL
```

#### Why This Is Resilient:
1. **Guaranteed Delivery (At-Least-Once):** The outbox event is persisted in the exact same relational transaction as the financial ledger entries. If the database rolls back, no outbox event is created. If it commits, the event is guaranteed to exist.
2. **Idempotent Ingestion:** The dispatcher uses MongoDB's unique `event_id` index with an upsert operation (`updateOne({ event_id }, { $setOnInsert: ... }, { upsert: true })`). If a network timeout causes the dispatcher to resend an event, MongoDB ignores the duplicate without error.

---

## 6. Synthesis: Recommended Enterprise Architecture

| Component | Technology | Primary Function | SLA / Consistency |
|---|---|---|---|
| **Authoritative Accounting Engine** | PostgreSQL 16 | Customer accounts, double-entry ledger, balance cache, transactional outbox | Immediate Consistency (ACID, CP) |
| **Audit & Telemetry Store** | MongoDB 7.0 | Transaction events, device fingerprints, fraud metadata, investigation trails | Eventual Consistency (Tunable, AP) |
| **Integration Bus** | Outbox Dispatcher (CDC / Polling) | Reliable asynchronous event streaming from PostgreSQL to MongoDB | At-least-once delivery + Idempotent deduplication |
