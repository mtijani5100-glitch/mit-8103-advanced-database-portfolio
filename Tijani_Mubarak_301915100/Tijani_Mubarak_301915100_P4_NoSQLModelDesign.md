# Portfolio 4: NoSQL Document Model Design
## LedgerSpring Digital Bank (LSDB) | Mubarak Tijani (ID: 301915100)

---

## 1. Domain Context & Architectural Separation

LedgerSpring Digital Bank (LSDB) employs a polyglot persistence architecture:

1. **Relational Core (PostgreSQL - Authoritative):**
   * Manages customer profiles, account balances, double-entry immutable ledgers, and atomic money movement.
   * Enforces strict ACID compliance, relational constraints, foreign keys, and pessimistic locking (`SELECT ... FOR UPDATE`).
2. **Document Store (MongoDB - Telemetry & Event Projection):**
   * Stores high-volume, append-only **transaction event streams, device telemetry, fraud audit trails, and multi-channel investigation metadata**.
   * Accommodates polymorphic metadata across channels (e.g., GPS coordinates from Mobile App, user-agent strings from Web, cell-tower IDs from USSD, session identifiers from central NIP switch).
   * Supports complex analytical aggregations (fraud pattern detection, failure rate categorization, latency monitoring) without loading down the core transactional database.

> **Core Invariant:** PostgreSQL is the sole authoritative system of record for account balances and financial postings. MongoDB is an event projection and analytical read store. MongoDB is **never** used to authorize transfers or compute live spendable balances.

---

## 2. Evaluation of NoSQL Paradigms for LedgerSpring Digital Bank

The NoSQL ecosystem encompasses four distinct data modeling paradigms. Below is an architectural evaluation of each paradigm within the LedgerSpring Digital Bank (LSDB) ecosystem:

| NoSQL Paradigm | Representative Engine | LSDB Architectural Role & Concrete Example | Suitability Evaluation & Trade-offs |
|---|---|---|---|
| **1. Document Store** *(Primary Implemented Model)* | **MongoDB 7.0 / BSON** | **Implemented: `transaction_events`**<br>Each document represents a polymorphic financial event containing embedded device telemetry, channel parameters, and NIP clearing metadata linked via `transaction_ref` to PostgreSQL. | **High Suitability for Event Projection:** Absorbs channel-specific polymorphic metadata (GPS from mobile, cell towers from USSD, IP/TLS from web) without relational schema migration. Supports rich secondary indexing and multi-stage aggregation pipelines. |
| **2. Key-Value Store** | **Redis / AWS DynamoDB** | **Candidate: Session & Idempotency Cache**<br>Key: `idempotency:P3-IDEM-KEY-001`<br>Value: `{ "status": "POSTED", "transaction_id": 1001, "hash": "sha256_payload_hash" }`<br>TTL: 86,400s (24 hours). | **High Suitability for Caching & Token Buckets:** Delivers sub-millisecond point lookups (`O(1)`) for API rate-limiting, user sessions, and rapid duplicate check filtering before hitting PostgreSQL. *Unsuitable* for multi-field analytics or complex querying. |
| **3. Wide-Column Store** | **Apache Cassandra / ScyllaDB** | **Candidate: Cold Historical Ledger Archival**<br>Partition Key: `account_number`<br>Clustering Column: `occurred_at DESC`<br>Columns: `transaction_id`, `amount_kobo`, `balance_after`, `counterparty_nuban`. | **High Suitability for Append-Only Petabyte Scale:** Linear horizontal write scalability across multiple geographically distributed data centres without single-point bottlenecks. *Unsuitable* for ad-hoc business aggregations or cross-partition relational rollups. |
| **4. Graph Database** | **Neo4j / Amazon Neptune** | **Candidate: Fraud Ring & AML Syndicate Detection**<br>Nodes: `(:Customer)`, `(:Account)`, `(:Device)`, `(:IP)`<br>Edges: `[:TRANSFERRED_TO]`, `[:LOGGED_IN_FROM]`, `[:SHARED_DEVICE]`. | **High Suitability for Relationship Traversals:** Solves k-hop circular payment detection (mule accounts, loan stacking, smurfing rings: A ➔ B ➔ C ➔ A) in milliseconds, where SQL joins would explode exponentially. *Unsuitable* for core ACID double-entry accounting. |

### Why the Document Model was Selected for Implementation:
LSDB specifically implemented the **Document Store (MongoDB)** because banking event telemetry requires a combination of:
1. **Hierarchical, nested data:** Capturing client device details, geo-location, and channel-specific payload attributes in a single atomic document read.
2. **Polymorphic schema flexibility:** Supporting differing metadata formats across Mobile App, USSD, Web Portal, and NIP Inward channels without sparse, null-heavy relational tables.
3. **Rich aggregation framework:** Computing failure rates, channel turnover, and fraud velocity natively without requiring specialized graph query engines.

---

## 3. Collection Design: `transaction_events`

The primary MongoDB collection is `transaction_events`. Each document represents a distinct, immutable point-in-time event occurring during a transaction's lifecycle.

### 2.1 JSON Schema Validation (`$jsonSchema`)

A MongoDB collection-level validator ensures document integrity while allowing channel-specific metadata polymorphism:

```json
{
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "event_id",
      "transaction_ref",
      "event_type",
      "occurred_at",
      "customer_id",
      "amount_ngn",
      "currency",
      "status",
      "channel"
    ],
    "properties": {
      "event_id": {
        "bsonType": "string",
        "pattern": "^EVT-[0-9]{4}-[A-Z0-9]+-[0-9]{3,}$",
        "description": "Unique business identifier for the event (e.g., EVT-2026-TRF-001-01)"
      },
      "transaction_ref": {
        "bsonType": "string",
        "description": "Cross-store reference linking back to PostgreSQL transactions.transaction_ref"
      },
      "event_type": {
        "enum": [
          "DEPOSIT_POSTED",
          "TRANSFER_INITIATED",
          "TRANSFER_POSTED",
          "TRANSFER_FAILED",
          "REVERSAL_POSTED",
          "AML_FLAG_RAISED",
          "SUSPICIOUS_LOGIN_FLAGGED"
        ],
        "description": "Event lifecycle classification"
      },
      "occurred_at": {
        "bsonType": "date",
        "description": "UTC timestamp when the event transpired"
      },
      "customer_id": {
        "bsonType": "int",
        "minimum": 1,
        "description": "Customer ID matching PostgreSQL customers.customer_id"
      },
      "source_account": {
        "bsonType": ["string", "null"],
        "description": "Originating 10-digit NUBAN account number"
      },
      "destination_account": {
        "bsonType": ["string", "null"],
        "description": "Beneficiary 10-digit NUBAN account number"
      },
      "amount_ngn": {
        "bsonType": "double",
        "minimum": 0.01,
        "description": "Transaction amount in Nigerian Naira"
      },
      "currency": {
        "enum": ["NGN"],
        "description": "Operational currency code"
      },
      "status": {
        "enum": ["INITIATED", "POSTED", "FAILED", "REVERSED", "FLAGGED"],
        "description": "Final state recorded by this event"
      },
      "channel": {
        "enum": ["MOBILE_APP", "WEB_PORTAL", "USSD", "NIP_INWARD", "POS_TERMINAL", "ATM"],
        "description": "Originating transaction channel"
      },
      "device_info": {
        "bsonType": "object",
        "description": "Embedded client telemetry captured at request ingestion"
      },
      "metadata": {
        "bsonType": "object",
        "description": "Channel-specific and diagnostic payload attributes"
      }
    }
  }
}
```

---

## 4. Embedding vs. Referencing Design Strategy

The data model makes deliberate choices between embedding and referencing:

| Document Section | Strategy | Justification |
|---|---|---|
| **Device Telemetry** (`device_info`) | **Embedded** | 1-to-1 relationship. Device model, IP address, OS version, and geographic coordinates represent an immutable snapshot of client state at the precise moment of execution. Always queried with the event. |
| **Operational Metadata** (`metadata`) | **Embedded** | Polymorphic key-value pairs (e.g. NIP session ID, AML risk score, reversal reason code). Embedding avoids schema bloat and allows schema evolution across channels without database alterations. |
| **Customer Entity** (`customer_id`) | **Referenced** | 1-to-many relationship. Customers are mutable core entities managed in PostgreSQL. Storing only the stable integer `customer_id` prevents data staleness (e.g. customer name or email changes) across millions of historical event documents. |
| **Account Numbers** (`source_account`, `destination_account`) | **Referenced** | Account numbers (NUBAN) are stable business keys. Storing account numbers provides fast filtering without replicating mutable account balances into MongoDB. |
| **Transaction Core** (`transaction_ref`) | **Referenced** | Cross-store foreign key tying the event directly to the relational transaction row in PostgreSQL. |

### Anti-Pattern Avoidance: Unbounded Arrays
LSDB specifically avoids the anti-pattern of embedding transaction event arrays inside a single `customer` document. In banking systems, customer transaction histories grow infinitely. Storing arrays inside customer documents would eventually breach MongoDB's 16 MB document size limit, cause massive memory thrashing during updates, and degrade indexing performance. By storing events as **individual documents** in `transaction_events`, the collection scales horizontally without document mutation.

---

## 5. Indexing Architecture

The collection features five strategic indexes tailored to high-frequency query patterns:

```javascript
// 1. Unique Idempotency Key: guarantees event uniqueness and eliminates duplicates
db.transaction_events.createIndex(
  { event_id: 1 },
  { unique: true, name: "idx_unique_event_id" }
);

// 2. Cross-store Reference: O(1) correlation with PostgreSQL transactions
db.transaction_events.createIndex(
  { transaction_ref: 1 },
  { name: "idx_transaction_ref" }
);

// 3. Customer Timeline Pagination: supports customer statement and activity feeds
db.transaction_events.createIndex(
  { customer_id: 1, occurred_at: -1 },
  { name: "idx_customer_timeline" }
);

// 4. Operational Diagnostics: supports monitoring and failure investigations
db.transaction_events.createIndex(
  { event_type: 1, occurred_at: -1 },
  { name: "idx_event_type_time" }
);

// 5. Security & AML Investigation: fast lookup by IP address and geolocation
db.transaction_events.createIndex(
  { "device_info.ip_address": 1 },
  { name: "idx_device_ip" }
);
```

---

## 6. Sample Document: Complete Mobile App Transfer Event

```json
{
  "event_id": "EVT-2026-TRF-001-01",
  "transaction_ref": "TXN-2026-TRF-001",
  "event_type": "TRANSFER_POSTED",
  "occurred_at": "2026-10-10T10:30:00.000Z",
  "customer_id": 1,
  "source_account": "1000000001",
  "destination_account": "2000000001",
  "amount_ngn": 75000.00,
  "currency": "NGN",
  "status": "POSTED",
  "channel": "MOBILE_APP",
  "device_info": {
    "ip_address": "102.89.34.12",
    "device_model": "iPhone 15 Pro",
    "os": "iOS 18.1",
    "geolocation": "Lagos, Nigeria",
    "device_fingerprint": "fp_ios_a9f81d4e72"
  },
  "correlation_id": "REQ-LAG-2026-001",
  "metadata": {
    "narration": "Professional equipment supplier payment",
    "latency_ms": 142,
    "nip_session_id": "0580002610101030000001",
    "beneficiary_bank_code": "058",
    "fee_kobo": 0,
    "fraud_risk_score": 0.04
  }
}
```
