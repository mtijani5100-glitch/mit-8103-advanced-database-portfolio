// Portfolio 4: NoSQL and Advanced Data Models
// Seed data script: 20 synthetic Nigerian banking events
// Mubarak Tijani (ID: 301915100)
// LedgerSpring Digital Bank (LSDB)

const DB_NAME = "lsdb_events";
const dbInstance = typeof db !== "undefined" ? db.getSiblingDB(DB_NAME) : null;

const SEED_EVENTS = [
  {
    event_id: "EVT-2026-FND-001-01",
    transaction_ref: "TXN-2026-FND-001",
    event_type: "DEPOSIT_POSTED",
    occurred_at: new Date("2026-09-11T09:15:22.000Z"),
    customer_id: NumberInt(1),
    source_account: "SYS0000001",
    destination_account: "1000000001",
    amount_ngn: 500000.00,
    currency: "NGN",
    status: "POSTED",
    channel: "NIP_INWARD",
    device_info: {
      ip_address: "197.210.8.45",
      device_model: "NIP Central Switch Gateway",
      os: "RedHat Enterprise Linux 9",
      geolocation: "Abuja, Nigeria",
      device_fingerprint: "gw_nip_switch_01"
    },
    correlation_id: "REQ-NIP-20260911-0001",
    metadata: {
      origin_bank: "058_GTCO",
      origin_account: "0123456789",
      narration: "SALARY/TECHCORP/SEP2026",
      latency_ms: 94,
      nip_session_id: "9990582609110915220000001",
      fraud_risk_score: 0.01
    }
  },
  {
    event_id: "EVT-2026-FND-002-01",
    transaction_ref: "TXN-2026-FND-002",
    event_type: "DEPOSIT_POSTED",
    occurred_at: new Date("2026-09-13T14:20:10.000Z"),
    customer_id: NumberInt(1),
    source_account: "SYS0000001",
    destination_account: "1000000002",
    amount_ngn: 120000.00,
    currency: "NGN",
    status: "POSTED",
    channel: "NIP_INWARD",
    device_info: {
      ip_address: "197.210.8.46",
      device_model: "NIP Central Switch Gateway",
      os: "RedHat Enterprise Linux 9",
      geolocation: "Abuja, Nigeria",
      device_fingerprint: "gw_nip_switch_02"
    },
    correlation_id: "REQ-NIP-20260913-0002",
    metadata: {
      origin_bank: "011_FIRSTBANK",
      origin_account: "2019151000",
      narration: "CONSULTING/RETAINER/SEP",
      latency_ms: 112,
      nip_session_id: "9990112609131420100000002",
      fraud_risk_score: 0.02
    }
  },
  {
    event_id: "EVT-2026-FND-003-01",
    transaction_ref: "TXN-2026-FND-003",
    event_type: "DEPOSIT_POSTED",
    occurred_at: new Date("2026-09-14T11:05:00.000Z"),
    customer_id: NumberInt(2),
    source_account: "SYS0000001",
    destination_account: "2000000001",
    amount_ngn: 2500000.00,
    currency: "NGN",
    status: "POSTED",
    channel: "NIP_INWARD",
    device_info: {
      ip_address: "197.210.8.45",
      device_model: "NIP Central Switch Gateway",
      os: "RedHat Enterprise Linux 9",
      geolocation: "Abuja, Nigeria",
      device_fingerprint: "gw_nip_switch_01"
    },
    correlation_id: "REQ-NIP-20260914-0003",
    metadata: {
      origin_bank: "033_UBA",
      origin_account: "1002003004",
      narration: "COMMERCIAL/SALES/INVENTORY",
      latency_ms: 130,
      nip_session_id: "9990332609141105000000003",
      fraud_risk_score: 0.05
    }
  },
  {
    event_id: "EVT-2026-TRF-001-01",
    transaction_ref: "TXN-2026-TRF-001",
    event_type: "TRANSFER_INITIATED",
    occurred_at: new Date("2026-09-18T10:14:02.000Z"),
    customer_id: NumberInt(1),
    source_account: "1000000001",
    destination_account: "2000000001",
    amount_ngn: 75000.00,
    currency: "NGN",
    status: "INITIATED",
    channel: "MOBILE_APP",
    device_info: {
      ip_address: "102.89.34.12",
      device_model: "iPhone 15 Pro",
      os: "iOS 18.1",
      geolocation: "Lagos, Nigeria",
      device_fingerprint: "fp_ios_a9f81d4e72"
    },
    correlation_id: "REQ-LAG-2026-TRF-001",
    metadata: {
      narration: "Equipment supplier payout",
      beneficiary_name: "Chukwudi Eze",
      fraud_risk_score: 0.03
    }
  },
  {
    event_id: "EVT-2026-TRF-001-02",
    transaction_ref: "TXN-2026-TRF-001",
    event_type: "TRANSFER_POSTED",
    occurred_at: new Date("2026-09-18T10:14:03.000Z"),
    customer_id: NumberInt(1),
    source_account: "1000000001",
    destination_account: "2000000001",
    amount_ngn: 75000.00,
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
    correlation_id: "REQ-LAG-2026-TRF-001",
    metadata: {
      narration: "Equipment supplier payout",
      latency_ms: 142,
      fee_kobo: 0,
      fraud_risk_score: 0.03
    }
  },
  {
    event_id: "EVT-2026-TRF-002-01",
    transaction_ref: "TXN-2026-TRF-002",
    event_type: "TRANSFER_POSTED",
    occurred_at: new Date("2026-09-20T16:45:00.000Z"),
    customer_id: NumberInt(2),
    source_account: "2000000001",
    destination_account: "3000000001",
    amount_ngn: 350000.00,
    currency: "NGN",
    status: "POSTED",
    channel: "WEB_PORTAL",
    device_info: {
      ip_address: "105.112.44.88",
      device_model: "MacBook Pro M3",
      os: "macOS 15.0",
      geolocation: "Ikeja, Lagos, Nigeria",
      device_fingerprint: "fp_mac_b8823f9901"
    },
    correlation_id: "REQ-IKJ-2026-TRF-002",
    metadata: {
      narration: "Consulting retainer payout",
      beneficiary_name: "Funmilayo Adeyemi",
      latency_ms: 185,
      fraud_risk_score: 0.04
    }
  },
  {
    event_id: "EVT-2026-TRF-003-01",
    transaction_ref: "TXN-2026-TRF-003",
    event_type: "TRANSFER_POSTED",
    occurred_at: new Date("2026-09-22T08:30:15.000Z"),
    customer_id: NumberInt(3),
    source_account: "3000000001",
    destination_account: "4000000001",
    amount_ngn: 15000.00,
    currency: "NGN",
    status: "POSTED",
    channel: "USSD",
    device_info: {
      ip_address: "197.210.64.12",
      device_model: "Nokia 105 Feature Phone",
      os: "Series 30+",
      geolocation: "Ibadan, Nigeria",
      device_fingerprint: "fp_ussd_cell_ibd_04"
    },
    correlation_id: "REQ-USSD-20260922-003",
    metadata: {
      narration: "Weekly logistics stipend",
      telco_provider: "MTN_NIGERIA",
      session_duration_sec: 18,
      latency_ms: 320,
      fraud_risk_score: 0.01
    }
  },
  {
    event_id: "EVT-2026-TRF-004-01",
    transaction_ref: "TXN-2026-TRF-004",
    event_type: "TRANSFER_POSTED",
    occurred_at: new Date("2026-09-25T13:10:00.000Z"),
    customer_id: NumberInt(4),
    source_account: "4000000001",
    destination_account: "6000000001",
    amount_ngn: 22000.00,
    currency: "NGN",
    status: "POSTED",
    channel: "MOBILE_APP",
    device_info: {
      ip_address: "102.89.45.101",
      device_model: "Samsung Galaxy S24",
      os: "Android 14",
      geolocation: "Port Harcourt, Nigeria",
      device_fingerprint: "fp_and_c1234ef567"
    },
    correlation_id: "REQ-PH-2026-TRF-004",
    metadata: {
      narration: "Sub-contractor invoice payment",
      latency_ms: 158,
      fraud_risk_score: 0.02
    }
  },
  {
    event_id: "EVT-2026-REV-001-01",
    transaction_ref: "TXN-2026-REV-001",
    event_type: "REVERSAL_POSTED",
    occurred_at: new Date("2026-09-26T15:00:00.000Z"),
    customer_id: NumberInt(2),
    source_account: "2000000001",
    destination_account: "1000000001",
    amount_ngn: 75000.00,
    currency: "NGN",
    status: "REVERSED",
    channel: "WEB_PORTAL",
    device_info: {
      ip_address: "197.210.8.10",
      device_model: "Dell OptiPlex Core Ops",
      os: "Windows 11 Enterprise",
      geolocation: "Victoria Island, Lagos, Nigeria",
      device_fingerprint: "fp_ops_portal_vi_01"
    },
    correlation_id: "REQ-OPS-RECALL-20260926",
    metadata: {
      original_transaction_ref: "TXN-2026-TRF-001",
      reversal_reason: "Operational recall: duplicate wire request by sender",
      authorized_by: "ops_officer_mubarak",
      fraud_risk_score: 0.00
    }
  },
  {
    event_id: "EVT-2026-FAIL-001-01",
    transaction_ref: "TXN-2026-FAIL-001",
    event_type: "TRANSFER_FAILED",
    occurred_at: new Date("2026-09-28T18:12:44.000Z"),
    customer_id: NumberInt(1),
    source_account: "1000000001",
    destination_account: "2000000001",
    amount_ngn: 1000000.00,
    currency: "NGN",
    status: "FAILED",
    channel: "MOBILE_APP",
    device_info: {
      ip_address: "102.89.34.12",
      device_model: "iPhone 15 Pro",
      os: "iOS 18.1",
      geolocation: "Lagos, Nigeria",
      device_fingerprint: "fp_ios_a9f81d4e72"
    },
    correlation_id: "REQ-FAIL-INSUF-001",
    metadata: {
      failure_code: "ERR_INSUFFICIENT_FUNDS",
      available_balance_seen: 425000.00,
      requested_amount: 1000000.00,
      shortfall_ngn: 575000.00,
      fraud_risk_score: 0.15
    }
  },
  {
    event_id: "EVT-2026-AML-001-01",
    transaction_ref: "TXN-2026-AML-001",
    event_type: "AML_FLAG_RAISED",
    occurred_at: new Date("2026-09-30T02:15:00.000Z"),
    customer_id: NumberInt(6),
    source_account: "6000000001",
    destination_account: "9100000001",
    amount_ngn: 4800000.00,
    currency: "NGN",
    status: "FLAGGED",
    channel: "WEB_PORTAL",
    device_info: {
      ip_address: "185.220.101.5",
      device_model: "Unknown Tor Exit Node",
      os: "Linux x86_64",
      geolocation: "Frankfurt, Germany",
      device_fingerprint: "fp_tor_suspicious_01"
    },
    correlation_id: "REQ-SEC-AML-20260930",
    metadata: {
      risk_rule: "VELOCITY_AND_GEO_ANOMALY",
      fraud_risk_score: 0.94,
      flag_reason: "High-value nocturnal transfer from foreign anonymizing proxy",
      action_taken: "TRANSACTION_HELD_FOR_COMPLIANCE_REVIEW"
    }
  },
  {
    event_id: "EVT-2026-FAIL-002-01",
    transaction_ref: "TXN-2026-FAIL-002",
    event_type: "TRANSFER_FAILED",
    occurred_at: new Date("2026-10-02T12:00:30.000Z"),
    customer_id: NumberInt(7),
    source_account: "7000000001",
    destination_account: "6000000002",
    amount_ngn: 50000.00,
    currency: "NGN",
    status: "FAILED",
    channel: "USSD",
    device_info: {
      ip_address: "197.210.70.33",
      device_model: "Itel 2160 Feature Phone",
      os: "Mocor OS",
      geolocation: "Kano, Nigeria",
      device_fingerprint: "fp_ussd_cell_kano_09"
    },
    correlation_id: "REQ-USSD-FAIL-002",
    metadata: {
      failure_code: "ERR_DESTINATION_SUSPENDED",
      destination_status: "SUSPENDED",
      telco_provider: "AIRTEL_NIGERIA",
      fraud_risk_score: 0.08
    }
  },
  {
    event_id: "EVT-2026-P3-IDEM-001",
    transaction_ref: "TXN-P3-IDEM-001",
    event_type: "TRANSFER_POSTED",
    occurred_at: new Date("2026-10-05T14:10:00.000Z"),
    customer_id: NumberInt(1),
    source_account: "P3-ALICE-001",
    destination_account: "P3-BOB-001",
    amount_ngn: 50000.00,
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
    correlation_id: "REQ-P3-IDEM-001",
    metadata: {
      idempotency_key: "P3-IDEM-KEY-001",
      retry_attempt: 0,
      latency_ms: 115,
      fraud_risk_score: 0.02
    }
  },
  {
    event_id: "EVT-2026-P3-RACE-A-01",
    transaction_ref: "TXN-P3-RACE-A",
    event_type: "TRANSFER_POSTED",
    occurred_at: new Date("2026-10-08T09:30:00.000Z"),
    customer_id: NumberInt(1),
    source_account: "P3-ALICE-001",
    destination_account: "P3-BOB-001",
    amount_ngn: 100000.00,
    currency: "NGN",
    status: "POSTED",
    channel: "WEB_PORTAL",
    device_info: {
      ip_address: "102.89.34.12",
      device_model: "Chrome on macOS",
      os: "macOS 15.0",
      geolocation: "Lagos, Nigeria",
      device_fingerprint: "fp_web_race_01"
    },
    correlation_id: "REQ-P3-CONCURRENCY-A",
    metadata: {
      lock_acquisition_order: "ASCENDING_ACCOUNT_ID",
      concurrency_group: "RACE_TEST_01",
      latency_ms: 140,
      fraud_risk_score: 0.01
    }
  },
  {
    event_id: "EVT-2026-P3-RACE-B-01",
    transaction_ref: "TXN-P3-RACE-B",
    event_type: "TRANSFER_POSTED",
    occurred_at: new Date("2026-10-08T09:30:01.000Z"),
    customer_id: NumberInt(1),
    source_account: "P3-ALICE-001",
    destination_account: "P3-BOB-001",
    amount_ngn: 100000.00,
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
    correlation_id: "REQ-P3-CONCURRENCY-B",
    metadata: {
      lock_wait_ms: 420,
      lock_status: "WAIT_THEN_ACQUIRED",
      concurrency_group: "RACE_TEST_01",
      fraud_risk_score: 0.01
    }
  },
  {
    event_id: "EVT-2026-POS-001-01",
    transaction_ref: "TXN-2026-POS-001",
    event_type: "TRANSFER_POSTED",
    occurred_at: new Date("2026-10-10T19:40:00.000Z"),
    customer_id: NumberInt(8),
    source_account: "8000000001",
    destination_account: "9300000001",
    amount_ngn: 8500.00,
    currency: "NGN",
    status: "POSTED",
    channel: "POS_TERMINAL",
    device_info: {
      ip_address: "197.210.12.99",
      device_model: "Pax A920 Smart POS",
      os: "PayDroid 10",
      geolocation: "Wuse II, Abuja, Nigeria",
      device_fingerprint: "pos_terminal_wuse_044"
    },
    correlation_id: "REQ-POS-20261010-8500",
    metadata: {
      merchant_name: "Jabi Lake Supermarket",
      merchant_mcc: "5411",
      card_scheme: "VERVE",
      latency_ms: 210,
      fraud_risk_score: 0.01
    }
  },
  {
    event_id: "EVT-2026-FAIL-003-01",
    transaction_ref: "TXN-2026-FAIL-003",
    event_type: "TRANSFER_FAILED",
    occurred_at: new Date("2026-10-12T07:15:10.000Z"),
    customer_id: NumberInt(9),
    source_account: "9000000001",
    destination_account: "9100000001",
    amount_ngn: 450000.00,
    currency: "NGN",
    status: "FAILED",
    channel: "MOBILE_APP",
    device_info: {
      ip_address: "105.112.99.14",
      device_model: "Xiaomi Redmi Note 13",
      os: "Android 13",
      geolocation: "Enugu, Nigeria",
      device_fingerprint: "fp_and_xm_9914"
    },
    correlation_id: "REQ-ENG-20261012-003",
    metadata: {
      failure_code: "ERR_INTERBANK_TIMEOUT",
      destination_bank: "070_FIDELITY",
      nip_response_code: "91_NETWORK_TIMEOUT",
      latency_ms: 35000,
      fraud_risk_score: 0.03
    }
  },
  {
    event_id: "EVT-2026-ATM-001-01",
    transaction_ref: "TXN-2026-ATM-001",
    event_type: "TRANSFER_POSTED",
    occurred_at: new Date("2026-10-14T21:10:00.000Z"),
    customer_id: NumberInt(10),
    source_account: "9100000001",
    destination_account: "SYS0000001",
    amount_ngn: 20000.00,
    currency: "NGN",
    status: "POSTED",
    channel: "ATM",
    device_info: {
      ip_address: "197.210.88.5",
      device_model: "NCR SelfServ 84 Walk-Up",
      os: "Windows 10 IoT",
      geolocation: "Benin City, Edo, Nigeria",
      device_fingerprint: "atm_terminal_benin_01"
    },
    correlation_id: "REQ-ATM-20261014-001",
    metadata: {
      atm_location: "Airport Road Branch, Benin City",
      cassette_notes_dispensed: "20 x 1000 NGN",
      latency_ms: 180,
      fraud_risk_score: 0.01
    }
  },
  {
    event_id: "EVT-2026-SEC-001-01",
    transaction_ref: "TXN-2026-SEC-001",
    event_type: "SUSPICIOUS_LOGIN_FLAGGED",
    occurred_at: new Date("2026-10-15T03:44:12.000Z"),
    customer_id: NumberInt(2),
    source_account: "2000000001",
    destination_account: null,
    amount_ngn: 0.01,
    currency: "NGN",
    status: "FLAGGED",
    channel: "MOBILE_APP",
    device_info: {
      ip_address: "185.220.101.5",
      device_model: "Emulated Android x86",
      os: "Android 10",
      geolocation: "Frankfurt, Germany",
      device_fingerprint: "fp_emulator_fraud_02"
    },
    correlation_id: "REQ-SEC-LOGIN-ANOMALY",
    metadata: {
      alert_type: "IMPOSSIBLE_TRAVEL_SPEED",
      last_known_city: "Lagos, Nigeria (45 minutes ago)",
      current_city: "Frankfurt, Germany",
      calculated_speed_kmh: 6800,
      action_taken: "2FA_CHALLENGE_TRIGGERED",
      fraud_risk_score: 0.98
    }
  },
  {
    event_id: "EVT-2026-TRF-005-01",
    transaction_ref: "TXN-2026-TRF-005",
    event_type: "TRANSFER_POSTED",
    occurred_at: new Date("2026-10-18T11:22:00.000Z"),
    customer_id: NumberInt(11),
    source_account: "9200000001",
    destination_account: "1000000001",
    amount_ngn: 180000.00,
    currency: "NGN",
    status: "POSTED",
    channel: "WEB_PORTAL",
    device_info: {
      ip_address: "105.112.18.77",
      device_model: "HP EliteBook 840",
      os: "Windows 11 Pro",
      geolocation: "Kano, Nigeria",
      device_fingerprint: "fp_web_kano_011"
    },
    correlation_id: "REQ-KAN-20261018-005",
    metadata: {
      narration: "Textile shipment procurement",
      beneficiary_name: "Amaka Okonkwo",
      latency_ms: 165,
      fraud_risk_score: 0.02
    }
  }
];

function seedEvents(database) {
  const targetDb = database || dbInstance;
  if (!targetDb) {
    throw new Error("No active MongoDB database handle provided.");
  }

  print(`[Seed] Ingesting ${SEED_EVENTS.length} events into ${targetDb.getName()}.transaction_events...`);
  
  // Use ordered: false so one failure doesn't halt the rest
  const result = targetDb.transaction_events.insertMany(SEED_EVENTS, { ordered: false });
  print(`[Seed] Successfully inserted ${result.insertedIds ? Object.keys(result.insertedIds).length : result.insertedCount} documents.`);
  
  const totalCount = targetDb.transaction_events.countDocuments();
  print(`[Seed] Total documents in collection: ${totalCount}`);
}

if (typeof db !== "undefined") {
  seedEvents(dbInstance);
}

if (typeof module !== "undefined") {
  module.exports = { seedEvents, SEED_EVENTS };
}
