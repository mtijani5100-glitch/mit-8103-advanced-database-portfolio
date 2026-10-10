# LedgerSpring Digital Bank: Business Rules

## Customer and account rules

1. Every customer has a unique internal identifier.
2. Each customer may own multiple customer accounts.
3. Every customer-facing account has a unique account number.
4. Closed or suspended accounts cannot initiate ordinary withdrawals or transfers.
5. The initial implementation supports NGN only.
6. Monetary values must use an exact decimal representation, such as PostgreSQL NUMERIC, rather than floating-point types.

## Financial transaction rules

7. Every deposit, withdrawal, transfer, and reversal must have a unique transaction reference.
8. The transaction amount must be greater than zero.
9. A transfer cannot have the same source and destination account.
10. Transfers require eligible accounts in the same currency.
11. An ordinary withdrawal or transfer cannot cause the customer's available balance to become negative.
12. A financial operation must either complete all required database changes or leave no partial financial posting.
13. Concurrent transactions must not spend the same available funds twice.
14. Each request that can be retried must use an idempotency key. Reusing the same key must not result in duplicate financial effects.

## Reversals and auditability

15. A reversal must preserve the original transaction and create a linked compensating financial record.
16. Only eligible completed transactions may be reversed.
17. The initial policy permits at most one full reversal per original transaction. Partial reversals can be considered separately.
18. A failed transaction that was never financially posted must not be credited or debited again merely to reverse it.
19. Financial records and audit events must retain their relevant history. Completed transactions must not be silently deleted or rewritten.
20. Reversal authorisation and the actor responsible must be recorded.

## Reconciliation and database integrity

21. Account balances must reconcile with the posted ledger entries according to the chosen accounting convention.
22. Every posted financial transaction must satisfy the selected ledger-balancing rules.
23. Foreign keys, unique constraints, NOT NULL constraints, and appropriate CHECK constraints must protect data integrity.
24. Audit queries must identify missing, duplicated, or inconsistent records.
25. Tests must cover successful operations, rejected operations, rollbacks, retries, concurrent requests, and reversal edge cases.

## Scope decisions

26. The initial system is a controlled academic simulation using synthetic data.
27. Deposits and withdrawals will be represented using appropriate system or settlement accounts in the ledger model.
28. Notifications and distributed event delivery are separate concerns from the authoritative financial posting.
29. Any rule that the database cannot enforce with a simple constraint must be implemented through an appropriate transaction, locking strategy, trigger, or reconciliation process and tested.
