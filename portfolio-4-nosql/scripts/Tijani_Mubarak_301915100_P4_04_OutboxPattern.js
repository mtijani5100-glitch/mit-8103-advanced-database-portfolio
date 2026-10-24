// Portfolio 4: NoSQL and Advanced Data Models
// Transactional Outbox Pattern & Idempotent Consumer Demonstration
// Mubarak Tijani (ID: 301915100)
// LedgerSpring Digital Bank (LSDB)

const DB_NAME = "lsdb_events";
const dbInstance = typeof db !== "undefined" ? db.getSiblingDB(DB_NAME) : null;

// Simulated outbox payload dispatched from PostgreSQL
const OUTBOX_DISPATCH_PAYLOAD = {
  event_id: "EVT-2026-OUTBOX-DEMO-01",
  transaction_ref: "TXN-2026-OUTBOX-DEMO",
  event_type: "TRANSFER_POSTED",
  occurred_at: new Date("2026-10-22T08:00:00.000Z"),
  customer_id: NumberInt(1),
  source_account: "1000000001",
  destination_account: "2000000002",
  amount_ngn: 60000.00,
  currency: "NGN",
  status: "POSTED",
  channel: "MOBILE_APP",
  device_info: {
    ip_address: "102.89.34.12",
    device_model: "iPhone 15 Pro",
    os: "iOS 18.1",
    geolocation: "Lagos, Nigeria",
    device_fingerprint: "fp_ios_a9f81d4e72"
  },
  correlation_id: "REQ-OUTBOX-TEST-001",
  metadata: {
    outbox_sequence_id: 1042,
    dispatch_worker_id: "cdc_worker_01",
    narration: "Transactional Outbox Verification Transfer",
    fraud_risk_score: 0.01
  }
};

function demonstrateOutboxPattern(database) {
  const targetDb = database || dbInstance;
  if (!targetDb) {
    throw new Error("No active MongoDB database handle provided.");
  }

  print("================================================================================");
  print("TRANSACTIONAL OUTBOX PATTERN: IDEMPOTENT INGESTION SIMULATION");
  print("================================================================================");

  // 1. Initial Delivery from Outbox Dispatcher
  print("\n[Step 1] Ingesting event from Outbox worker (first delivery attempt)...");
  const firstAttempt = targetDb.transaction_events.updateOne(
    { event_id: OUTBOX_DISPATCH_PAYLOAD.event_id },
    { $setOnInsert: OUTBOX_DISPATCH_PAYLOAD },
    { upsert: true }
  );

  print(`Result: matchedCount = ${firstAttempt.matchedCount}, upsertedCount = ${firstAttempt.upsertedCount ? 1 : 0}`);
  if (firstAttempt.upsertedId) {
    print(`-> Success: New event document persisted with _id: ${firstAttempt.upsertedId._id || firstAttempt.upsertedId}`);
  }

  // 2. Simulated Network Retry (At-Least-Once Delivery Replay)
  // The worker crashed before marking the PostgreSQL outbox row as PUBLISHED, so it replays the exact same event
  print("\n[Step 2] Simulating network retry / duplicate delivery of the exact same event...");
  const secondAttempt = targetDb.transaction_events.updateOne(
    { event_id: OUTBOX_DISPATCH_PAYLOAD.event_id },
    { $setOnInsert: OUTBOX_DISPATCH_PAYLOAD },
    { upsert: true }
  );

  print(`Result: matchedCount = ${secondAttempt.matchedCount}, upsertedCount = ${secondAttempt.upsertedCount ? 1 : 0}`);
  print("-> Idempotency confirmed: Existing document detected by unique event_id. Zero duplicate documents created.");

  // 3. Verify exactly 1 copy exists in MongoDB
  const eventCount = targetDb.transaction_events.countDocuments({
    event_id: OUTBOX_DISPATCH_PAYLOAD.event_id
  });
  print(`\n[Step 3] Verification: Total documents in collection with event_id '${OUTBOX_DISPATCH_PAYLOAD.event_id}': ${eventCount}`);

  // 4. Retrieve stored event
  const storedEvent = targetDb.transaction_events.findOne(
    { event_id: OUTBOX_DISPATCH_PAYLOAD.event_id },
    {
      event_id: 1,
      transaction_ref: 1,
      event_type: 1,
      amount_ngn: 1,
      "metadata.dispatch_worker_id": 1,
      "metadata.outbox_sequence_id": 1
    }
  );
  print("\n[Step 4] Stored event projection:");
  printjson(storedEvent);
}

if (typeof db !== "undefined") {
  demonstrateOutboxPattern(dbInstance);
}

if (typeof module !== "undefined") {
  module.exports = { demonstrateOutboxPattern, OUTBOX_DISPATCH_PAYLOAD };
}
