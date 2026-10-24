// Portfolio 4: NoSQL and Advanced Data Models
// Collection setup and index creation script
// Mubarak Tijani (ID: 301915100)
// LedgerSpring Digital Bank (LSDB)

const DB_NAME = "lsdb_events";
const dbInstance = typeof db !== "undefined" ? db.getSiblingDB(DB_NAME) : null;

function setupCollection(database) {
  const targetDb = database || dbInstance;
  if (!targetDb) {
    throw new Error("No active MongoDB database handle provided.");
  }

  print(`[Setup] Target database: ${targetDb.getName()}`);

  // Drop existing test collection if resetting
  targetDb.transaction_events.drop();
  print("[Setup] Cleaned up any pre-existing transaction_events collection.");

  // Create collection with strict JSON Schema Validator
  targetDb.createCollection("transaction_events", {
    validator: {
      $jsonSchema: {
        bsonType: "object",
        required: [
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
        properties: {
          event_id: {
            bsonType: "string",
            pattern: "^EVT-[0-9]{4}-[A-Z0-9]+-[0-9A-Z]+$",
            description: "Must be a valid business event ID (e.g., EVT-2026-TRF-001-01)"
          },
          transaction_ref: {
            bsonType: "string",
            description: "Foreign reference to PostgreSQL transactions table"
          },
          event_type: {
            enum: [
              "DEPOSIT_POSTED",
              "TRANSFER_INITIATED",
              "TRANSFER_POSTED",
              "TRANSFER_FAILED",
              "REVERSAL_POSTED",
              "AML_FLAG_RAISED",
              "SUSPICIOUS_LOGIN_FLAGGED"
            ],
            description: "Valid event lifecycle type"
          },
          occurred_at: {
            bsonType: "date",
            description: "Timestamp when the event occurred in UTC"
          },
          customer_id: {
            bsonType: "int",
            minimum: 1,
            description: "Positive customer identifier"
          },
          source_account: {
            bsonType: ["string", "null"]
          },
          destination_account: {
            bsonType: ["string", "null"]
          },
          amount_ngn: {
            bsonType: "double",
            minimum: 0.01,
            description: "Amount in NGN"
          },
          currency: {
            enum: ["NGN"]
          },
          status: {
            enum: ["INITIATED", "POSTED", "FAILED", "REVERSED", "FLAGGED"]
          },
          channel: {
            enum: ["MOBILE_APP", "WEB_PORTAL", "USSD", "NIP_INWARD", "POS_TERMINAL", "ATM"]
          },
          device_info: {
            bsonType: "object"
          },
          metadata: {
            bsonType: "object"
          }
        }
      }
    },
    validationLevel: "strict",
    validationAction: "error"
  });
  print("[Setup] Created collection 'transaction_events' with $jsonSchema validation.");

  // Register strategic indexes
  print("[Setup] Building strategic indexes...");

  // 1. Unique idempotency index
  targetDb.transaction_events.createIndex(
    { event_id: 1 },
    { unique: true, name: "idx_unique_event_id" }
  );

  // 2. Cross-store point lookup
  targetDb.transaction_events.createIndex(
    { transaction_ref: 1 },
    { name: "idx_transaction_ref" }
  );

  // 3. Customer activity timeline with reverse chronologic ordering
  targetDb.transaction_events.createIndex(
    { customer_id: 1, occurred_at: -1 },
    { name: "idx_customer_timeline" }
  );

  // 4. Operational failure & diagnostic monitoring index
  targetDb.transaction_events.createIndex(
    { event_type: 1, occurred_at: -1 },
    { name: "idx_event_type_time" }
  );

  // 5. Fraud and security investigation index
  targetDb.transaction_events.createIndex(
    { "device_info.ip_address": 1 },
    { name: "idx_device_ip" }
  );

  const indexes = targetDb.transaction_events.getIndexes();
  print(`[Setup] Successfully registered ${indexes.length} indexes on transaction_events:`);
  indexes.forEach(idx => print(` - ${idx.name}: ${JSON.stringify(idx.key)}`));
}

if (typeof db !== "undefined") {
  setupCollection(dbInstance);
}

if (typeof module !== "undefined") {
  module.exports = { setupCollection };
}
