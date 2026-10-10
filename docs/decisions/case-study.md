# Case Study: LedgerSpring Digital Bank (LSDB)

## 1. Organisation Overview

LedgerSpring Digital Bank (LSDB) is a fictional Nigerian digital banking platform created for the MIT 8103 Advanced Database Systems practical portfolio. The platform provides customers with accounts and supports deposits, withdrawals, internal transfers, transaction history, reversal of failed or eligible transactions, and account balance reconciliation.

The implementation uses synthetic data exclusively. It does not connect to a real bank or process real customer funds.

## 2. Database Users

- Customers: own accounts and initiate banking operations.
- Bank operations staff: investigate transaction failures and process authorised reversals.
- Auditors: inspect financial records and reconcile account balances.
- Database administrators: manage database availability, access, backup, and recovery.
- Background processes: perform reconciliation, transaction monitoring, and other automated tasks.

## 3. Data to Be Stored

The relational database will store customer records, bank accounts, financial transactions, ledger entries, transaction idempotency keys, and audit records.

A document database may subsequently store transaction notifications or application activity events for the NoSQL portfolio.

## 4. Core Operations

1. Register customers and open accounts.
2. Deposit funds and withdraw funds.
3. Transfer funds between eligible accounts.
4. Prevent duplicate processing of retried requests.
5. Record and investigate failed transactions.
6. Reverse eligible completed transactions without deleting their history.
7. Retrieve transaction histories and optimise reporting queries.
8. Reconcile account balances against financial ledger records.
9. Explore replication, partitioning, availability, and recovery for a distributed banking architecture.

## 5. Technology Scope

- Primary relational database: PostgreSQL.
- NoSQL database: MongoDB for a selected activity or event data model.
- Version control and documentation: Git and GitHub.
- Entity-relationship modelling: diagrams.net.
- Evidence: SQL scripts, query outputs, execution plans, test results, diagrams, and screenshots.

## 6. Assumptions and Limitations

The initial implementation uses Nigerian naira (NGN) and synthetic customers. External interbank payments, foreign exchange, regulatory integrations, real identity verification, and production payment processing are outside the initial implementation scope.

Security, database permissions, backups, and recovery will be discussed or demonstrated to the extent required by the assignment. This academic simulation is not a production-ready banking application.
