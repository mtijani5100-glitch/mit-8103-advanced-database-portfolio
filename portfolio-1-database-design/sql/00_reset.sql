-- =============================================================================
-- Portfolio 1: Database Design and Modelling
-- LedgerSpring Digital Bank (LSDB) — Database Reset Script
-- MIT 8103 Advanced Database Systems
--
-- PURPOSE: Drop all LSDB tables (in FK-safe reverse order) and reset sequences.
--          Run this before re-running 01_create_schema.sql to start completely fresh.
--
-- Usage: psql -d ledgerspring -f sql/00_reset.sql
-- =============================================================================

\echo '--- Dropping all LSDB tables (reverse FK order) ---'

DROP TABLE IF EXISTS audit_logs        CASCADE;
DROP TABLE IF EXISTS idempotency_keys  CASCADE;
DROP TABLE IF EXISTS ledger_entries    CASCADE;
DROP TABLE IF EXISTS transactions      CASCADE;
DROP TABLE IF EXISTS accounts          CASCADE;
DROP TABLE IF EXISTS customers         CASCADE;

\echo '--- All tables dropped. Ready to run 01_create_schema.sql ---'
