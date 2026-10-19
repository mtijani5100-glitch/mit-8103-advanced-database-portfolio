LedgerSpring Digital Bank ERD v1

- Tijani_Mubarak_301915100_ERD_v1.drawio: editable diagrams.net source (v1). Open https://app.diagrams.net/ and use File > Open From > Device.
- Tijani_Mubarak_301915100_ERD_v1.png: high-resolution PNG preview (v1).
- Tijani_Mubarak_301915100_ERD_v1.svg: vector preview (v1).
- Tijani_Mubarak_301915100_ERD_v2.drawio: editable diagrams.net source (v2 final schema).
- Tijani_Mubarak_301915100_ERD_v2.png: high-resolution PNG preview (v2 final schema).

Core relationships:
- One customer can own zero or many customer accounts; SETTLEMENT/SUSPENSE accounts may have no customer owner.
- Account source and destination references are optional to accommodate deposits and withdrawals; transfers require both and must use different customer accounts. SETTLEMENT/SUSPENSE accounts provide balancing ledger counterparts for deposits and withdrawals.
- One transaction can have zero or many ledger entries before posting. A posted transaction must have balanced postings.
- One account can have zero or many ledger entries.
- Audit logs can optionally refer to a transaction.
- A reversal is a separate transaction linked to its original through reversal_of_transaction_id.

Review the diagram and keep it synchronized with your implemented SQL schema.

This is ERD version 1, so treat it as the initial design rather than the final database model.
The diagram includes five core entities:
- CUSTOMERS: customer details.
- ACCOUNTS: customer, settlement, and suspense accounts.
- TRANSACTIONS: deposits, withdrawals, transfers, and reversals.
- LEDGER_ENTRIES: the debit and credit postings for financial operations.
- AUDIT_LOGS: records of significant actions.
One particularly important design choice is the distinction between customer and system accounts. A deposit or withdrawal needs a balancing ledger entry against a settlement or other system account. Therefore, the eventual SQL schema must allow system accounts without a customer owner, while ensuring that customer-owned accounts have a valid customer reference.
Your transfer implementation must also enforce sufficient funds, prevent duplicate processing, and post the sender's debit and recipient's credit atomically.
