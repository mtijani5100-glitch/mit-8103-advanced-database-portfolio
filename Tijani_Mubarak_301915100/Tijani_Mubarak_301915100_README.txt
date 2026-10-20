MIT 8103 Advanced Database Systems — Continuous Assessment
Student Name: Mubarak Tijani
Student ID: 301915100
Course: MIT 8103 Advanced Database Systems
Session: 2026/2027 Academic Session (September Cohort)
Institution: Miva Open University
Case Study: LedgerSpring Digital Bank (LSDB) — Core Banking & Double-Entry Ledger System
GitHub Repository: https://github.com/mtijani5100-glitch/mit-8103-advanced-database-portfolio.git

================================================================================
SUBMISSION OVERVIEW
================================================================================
This submission folder contains the deliverables and empirical evidence for:
- Portfolio 1: Database Design and Modelling (7 Marks)
- Portfolio 2: Query Processing and Optimisation (7 Marks)

All files follow the required naming format: Surname_Firstname_StudentID_DocumentType
No spaces are used in any file or folder names.

================================================================================
PORTFOLIO 1: DATABASE DESIGN AND MODELLING
================================================================================
1. Case Study & Architecture:
   - Tijani_Mubarak_301915100_P1_CaseStudy.md: Domain context, core actors, and accounting invariants.
   - Tijani_Mubarak_301915100_BusinessRules.md: 29 formal business rules.
   - Tijani_Mubarak_301915100_EnvironmentSpecs.md: Environment specifications (PostgreSQL 16.13, macOS ARM64).

2. Relational Schema & Modeling:
   - Tijani_Mubarak_301915100_P1_CreateSchema.sql: PostgreSQL DDL with 6 core tables and constraints.
   - Tijani_Mubarak_301915100_P1_RelationalSchema.md: Complete data dictionary with keys and check constraints.
   - Tijani_Mubarak_301915100_P1_Normalisation.md: Normalisation analysis proving 3NF / BCNF compliance.
   - Tijani_Mubarak_301915100_P1_ERD.png: Entity-Relationship Diagram visual export.
   - Tijani_Mubarak_301915100_P1_ERD.drawio: Editable Entity-Relationship Diagram source (diagrams.net).

3. Testing & Execution:
   - Tijani_Mubarak_301915100_P1_Reset.sql: Safe database teardown script.
   - Tijani_Mubarak_301915100_P1_SeedData.sql: Synthetic seed dataset with atomic deposit transactions.
   - Tijani_Mubarak_301915100_P1_ConstraintTests.sql: 11 PL/pgSQL constraint assertion test blocks.
   - Tijani_Mubarak_301915100_P1_EdgeCaseTestMatrix.md: Documented matrix of the 11 edge cases (all PASS).

4. Visual Execution Evidence:
   - Tijani_Mubarak_301915100_P1_Evidence_01_CustomerTable.png
   - Tijani_Mubarak_301915100_P1_Evidence_02_AccountsTable.png
   - Tijani_Mubarak_301915100_P1_Evidence_03_TransactionsTable.png
   - Tijani_Mubarak_301915100_P1_Evidence_04_LedgerEntries.png
   - Tijani_Mubarak_301915100_P1_Evidence_05_IdempotencyKeys.png
   - Tijani_Mubarak_301915100_P1_Evidence_06_AuditLogs.png
   - Tijani_Mubarak_301915100_P1_Evidence_07_Reset.png: pgAdmin execution output for database reset script.
   - Tijani_Mubarak_301915100_P1_Evidence_08_CreateSchema.png: pgAdmin execution output for schema creation DDL.
   - Tijani_Mubarak_301915100_P1_Evidence_09_SeedData.png: pgAdmin execution output for Nigerian banking seed data.
   - Tijani_Mubarak_301915100_P1_Evidence_10_Constraints.png: pgAdmin execution output showing all 11 constraint tests PASS.

================================================================================
PORTFOLIO 2: QUERY PROCESSING AND OPTIMISATION
================================================================================
1. Benchmark Analysis & Documentation:
   - Tijani_Mubarak_301915100_P2_README.md: Portfolio 2 implementation overview and instructions.
   - Tijani_Mubarak_301915100_P2_PerformanceResults.md: Technical report detailing Cost-Based Optimizer
     (CBO) formulas, small-table economics, buffer reads, and index lifecycle trade-offs.

2. Benchmark & Indexing Scripts:
   - Tijani_Mubarak_301915100_P2_BaselinePlans.sql: Automated capture of baseline execution plans.
   - Tijani_Mubarak_301915100_P2_CreateIndexes.sql: Index migration (composite and partial B-trees).
   - Tijani_Mubarak_301915100_P2_OptimisedPlans.sql: Automated capture of post-optimisation execution plans.
   - Tijani_Mubarak_301915100_P2_AllBaselinePlans.txt: Consolidated baseline EXPLAIN ANALYZE output.
   - Tijani_Mubarak_301915100_P2_AllOptimisedPlans.txt: Consolidated post-optimisation EXPLAIN ANALYZE output.

3. The 10 Banking Query Implementations:
   - Tijani_Mubarak_301915100_P2_Q01_CustomerAccounts.sql: Customer dashboard accounts lookup.
   - Tijani_Mubarak_301915100_P2_Q02_AccountTxHistory.sql: Paginated bilateral account history.
   - Tijani_Mubarak_301915100_P2_Q03_TransactionLookup.sql: Point lookup by unique transaction reference.
   - Tijani_Mubarak_301915100_P2_Q04_OperationsFailures.sql: Operational monitoring for pending/failed transfers.
   - Tijani_Mubarak_301915100_P2_Q05_DailyTotals.sql: Daily clearing aggregate volume and value.
   - Tijani_Mubarak_301915100_P2_Q06_HighValueTransfers.sql: AML compliance threshold filter (> 50,000 NGN).
   - Tijani_Mubarak_301915100_P2_Q07_BalanceReconciliation.sql: Automated balance reconciliation (0 discrepancies).
   - Tijani_Mubarak_301915100_P2_Q08_UnbalancedJournals.sql: Audit check for unbalanced entries (0 violations).
   - Tijani_Mubarak_301915100_P2_Q09_NetMovementReversals.sql: Reversal-adjusted financial volume summary.
   - Tijani_Mubarak_301915100_P2_Q10_FullJoinReport.sql: Multi-table financial audit report.

4. Execution Plan Visual Evidence (pgAdmin / Terminal Outputs):
   - Tijani_Mubarak_301915100_P2_Evidence_01_Q01_Plan.png
   - Tijani_Mubarak_301915100_P2_Evidence_02_Q02_Plan.png
   - Tijani_Mubarak_301915100_P2_Evidence_03_Q03_Plan.png
   - Tijani_Mubarak_301915100_P2_Evidence_04_Q04_Plan.png
   - Tijani_Mubarak_301915100_P2_Evidence_05_Q05_Plan.png
   - Tijani_Mubarak_301915100_P2_Evidence_06_Q06_Plan.png
   - Tijani_Mubarak_301915100_P2_Evidence_07_Q07_Plan.png
   - Tijani_Mubarak_301915100_P2_Evidence_08_Q08_Plan.png
   - Tijani_Mubarak_301915100_P2_Evidence_09_Q09_Plan.png
   - Tijani_Mubarak_301915100_P2_Evidence_10_Q10_Plan.png
