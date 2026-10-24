// Portfolio 4: NoSQL and Advanced Data Models
// Queries and Aggregation Pipelines
// Mubarak Tijani (ID: 301915100)
// LedgerSpring Digital Bank (LSDB)

const DB_NAME = "lsdb_events";
const dbInstance = typeof db !== "undefined" ? db.getSiblingDB(DB_NAME) : null;

function runQueriesAndAggregations(database) {
  const targetDb = database || dbInstance;
  if (!targetDb) {
    throw new Error("No active MongoDB database handle provided.");
  }

  print("================================================================================");
  print("QUERY 1: Customer Activity Feed (Customer 1 - Amaka Okonkwo, Paginated)");
  print("Uses index: idx_customer_timeline { customer_id: 1, occurred_at: -1 }");
  print("================================================================================");
  const q1 = targetDb.transaction_events
    .find(
      { customer_id: 1 },
      {
        event_id: 1,
        transaction_ref: 1,
        event_type: 1,
        amount_ngn: 1,
        channel: 1,
        status: 1,
        occurred_at: 1,
        "metadata.narration": 1
      }
    )
    .sort({ occurred_at: -1 })
    .limit(5);

  q1.forEach(doc => printjson(doc));


  print("\n================================================================================");
  print("QUERY 2: Full Lifecycle Point Lookup by Transaction Reference (TXN-2026-TRF-001)");
  print("Uses index: idx_transaction_ref { transaction_ref: 1 }");
  print("================================================================================");
  const q2 = targetDb.transaction_events
    .find(
      { transaction_ref: "TXN-2026-TRF-001" },
      {
        event_id: 1,
        event_type: 1,
        occurred_at: 1,
        status: 1,
        "device_info.ip_address": 1,
        "metadata.latency_ms": 1
      }
    )
    .sort({ occurred_at: 1 });

  q2.forEach(doc => printjson(doc));


  print("\n================================================================================");
  print("QUERY 3: Operational Diagnostics — Failed Transfers with Failure Reason");
  print("Uses index: idx_event_type_time { event_type: 1, occurred_at: -1 }");
  print("================================================================================");
  const q3 = targetDb.transaction_events.find(
    { status: "FAILED" },
    {
      event_id: 1,
      transaction_ref: 1,
      customer_id: 1,
      amount_ngn: 1,
      channel: 1,
      "metadata.failure_code": 1,
      "metadata.shortfall_ngn": 1,
      occurred_at: 1
    }
  );

  q3.forEach(doc => printjson(doc));


  print("\n================================================================================");
  print("AGGREGATION 1: Failure Distribution by Error Reason & Channel");
  print("Identifies systemic network timeouts vs. customer insufficient funds");
  print("================================================================================");
  const agg1 = targetDb.transaction_events.aggregate([
    {
      $match: {
        status: "FAILED"
      }
    },
    {
      $group: {
        _id: {
          failure_code: "$metadata.failure_code",
          channel: "$channel"
        },
        failure_count: { $sum: 1 },
        total_failed_volume_ngn: { $sum: "$amount_ngn" },
        affected_customers: { $addToSet: "$customer_id" }
      }
    },
    {
      $project: {
        _id: 0,
        failure_code: "$_id.failure_code",
        channel: "$_id.channel",
        failure_count: 1,
        total_failed_volume_ngn: 1,
        distinct_customer_count: { $size: "$affected_customers" }
      }
    },
    {
      $sort: { failure_count: -1 }
    }
  ]);

  agg1.forEach(doc => printjson(doc));


  print("\n================================================================================");
  print("AGGREGATION 2: Multi-Channel Performance & Turnover Breakdown");
  print("Calculates total posted volume, value, and average processing latency per channel");
  print("================================================================================");
  const agg2 = targetDb.transaction_events.aggregate([
    {
      $match: {
        status: "POSTED"
      }
    },
    {
      $group: {
        _id: "$channel",
        transaction_count: { $sum: 1 },
        total_turnover_ngn: { $sum: "$amount_ngn" },
        avg_amount_ngn: { $avg: "$amount_ngn" },
        avg_latency_ms: { $avg: "$metadata.latency_ms" }
      }
    },
    {
      $project: {
        _id: 0,
        channel: "$_id",
        transaction_count: 1,
        total_turnover_ngn: { $round: ["$total_turnover_ngn", 2] },
        avg_amount_ngn: { $round: ["$avg_amount_ngn", 2] },
        avg_latency_ms: { $round: ["$avg_latency_ms", 1] }
      }
    },
    {
      $sort: { total_turnover_ngn: -1 }
    }
  ]);

  agg2.forEach(doc => printjson(doc));


  print("\n================================================================================");
  print("AGGREGATION 3: Security & Fraud Investigation — High Risk & Anomaly Audit");
  print("Flags suspicious transactions where fraud_risk_score >= 0.70");
  print("================================================================================");
  const agg3 = targetDb.transaction_events.aggregate([
    {
      $match: {
        "metadata.fraud_risk_score": { $gte: 0.70 }
      }
    },
    {
      $project: {
        _id: 0,
        event_id: 1,
        event_type: 1,
        customer_id: 1,
        amount_ngn: 1,
        risk_score: "$metadata.fraud_risk_score",
        alert_type: { $ifNull: ["$metadata.alert_type", "$metadata.flag_reason"] },
        ip_address: "$device_info.ip_address",
        geolocation: "$device_info.geolocation",
        action_taken: "$metadata.action_taken",
        occurred_at: 1
      }
    },
    {
      $sort: { risk_score: -1 }
    }
  ]);

  agg3.forEach(doc => printjson(doc));
}

if (typeof db !== "undefined") {
  runQueriesAndAggregations(dbInstance);
}

if (typeof module !== "undefined") {
  module.exports = { runQueriesAndAggregations };
}
