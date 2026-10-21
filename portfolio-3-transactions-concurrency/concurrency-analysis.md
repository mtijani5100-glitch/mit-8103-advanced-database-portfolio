# Portfolio 3: Concurrency Analysis
## LedgerSpring Digital Bank (LSDB) | Mubarak Tijani | ID: 301915100

---

## 1. Scope

This document covers the lock model, isolation level choices, deadlock
avoidance strategy, and retry behaviour used in the LSDB PostgreSQL
implementation as demonstrated by the Portfolio 3 SQL scripts.

---

## 2. Locking Strategy

### 2.1 Row-level locking with SELECT FOR UPDATE

Every money-movement path (transfer, reversal, insufficient-funds check)
acquires an exclusive row lock on all affected account rows before
reading the balance or writing any ledger entry. This is done with:

```sql
SELECT available_balance FROM accounts WHERE account_id = $1 FOR UPDATE;
```

The lock is held until the surrounding transaction commits or rolls back.
No other session can modify or lock the same row in the interval, which
makes the balance check and subsequent debit/credit a single atomic unit
from the perspective of concurrent sessions.

### 2.2 Deterministic lock ordering to prevent deadlocks

A classic deadlock occurs when Session A locks account X and waits for
account Y, while Session B holds Y and waits for X. LSDB avoids this by
always acquiring multiple account locks in **ascending account_id order**:

```sql
v_min := LEAST(v_alice, v_bob);
v_max := GREATEST(v_alice, v_bob);

PERFORM account_id FROM accounts WHERE account_id = v_min FOR UPDATE;
PERFORM account_id FROM accounts WHERE account_id = v_max FOR UPDATE;
```

Because every concurrent session follows the same ordering, two sessions
transferring in opposite directions between the same pair of accounts will
always queue on the lower-id lock — one proceeds while the other waits,
then the waiter re-checks the balance after acquiring the lock. The
circular wait condition that causes deadlocks cannot form.

### 2.3 Guarded atomic balance update

Even after acquiring the row lock, the available balance is re-read from
the database (not from application memory) before the guard check:

```sql
SELECT available_balance INTO v_bal FROM accounts WHERE account_id = v_alice FOR UPDATE;
IF v_bal < v_amount THEN ... REJECT ... END IF;
```

This eliminates the time-of-check/time-of-use window that exists when
the balance is read by one statement and compared in application code
before a separate UPDATE is issued later.

---

## 3. Isolation Levels

| Level | PostgreSQL behaviour | Used in P3? |
|---|---|---|
| READ UNCOMMITTED | Treated as READ COMMITTED; no dirty reads | No |
| READ COMMITTED | Each statement gets a fresh snapshot. Non-repeatable reads are possible between statements in the same transaction. | Yes (default, all transfer scripts) |
| REPEATABLE READ | Stable snapshot for the whole transaction. Concurrent committed writes are invisible until the transaction ends. Conflicting write transactions abort. | Yes (isolation demo 1B) |
| SERIALIZABLE | Full serializable execution. Phantom reads blocked. Conflicting patterns raise serialization failure errors; caller must retry. | Described; not used in transfer path |

### 3.1 READ COMMITTED (default)

The transfer scripts run at READ COMMITTED. The `SELECT ... FOR UPDATE`
locking, not the isolation level, is what prevents lost updates and
overdrafts. Isolation alone at READ COMMITTED does not prevent two
sessions from both reading the same balance if neither holds a lock; the
FOR UPDATE call is therefore mandatory in every posting path.

### 3.2 REPEATABLE READ

Demonstrated in isolation script 1B. Both balance reads in the same
transaction return the same value even after another session commits a
change between them. This level is not used in the posting path because
FOR UPDATE achieves the same serialisation effect with less overhead and
clearer semantics for financial code.

### 3.3 Why SERIALIZABLE is documented but not chosen for the transfer path

SERIALIZABLE prevents write skew and phantom reads. However, it raises
serialization failure errors that require the entire transaction to be
retried — including re-running every application-side validation. For a
two-account transfer where the only shared state is the account balance,
`SELECT ... FOR UPDATE` achieves the same correctness guarantee without
requiring application-level retry logic for every contention event.
SERIALIZABLE would be appropriate for complex multi-table invariants where
row-level locking is impractical.

---

## 4. Deadlock Reproduction and Resolution

### 4.1 Deliberate deadlock (Exercise G)

The deadlock scenario in `P3_ConcurrencyTests.sql` Part 3 uses reverse
lock ordering intentionally:

- Session A: locks Alice, sleeps, then tries to lock Charlie.
- Session B: locks Charlie, sleeps, then tries to lock Alice.

PostgreSQL's deadlock detector wakes periodically (default: every 1 s,
controlled by `deadlock_timeout`). When it detects the cycle, it chooses
one victim and rolls back that session's entire transaction, raising:

```
ERROR: deadlock detected
DETAIL: Process ... waits for ShareLock on transaction ...; blocked by process ...
```

The surviving session then completes. The rolled-back session receives
the error and must retry the **entire** transaction from the beginning —
not just the last statement, because earlier effects may have altered
intermediate state.

### 4.2 Safe resolution: deterministic lock ordering

The safe version in the same script uses `LEAST`/`GREATEST` to sort the
two account IDs before acquiring locks. When both sessions follow this
ordering, the lower-ID account always becomes the first lock. Both
sessions queue on that lock; one proceeds completely, the other waits
and then wins. No cycle can form, so no deadlock occurs.

### 4.3 Retry policy

In production, the application wraps every transfer in a retry loop with:

- A bounded retry count (e.g., 3 attempts).
- A short random back-off between attempts.
- The entire transaction is retried, not just the failing statement.
- The idempotency key ensures that if the original request completed
  before the caller received the error, the retry returns the original
  result without a duplicate posting.

---

## 5. Preventing Overdrafts and Lost Updates

The PostgreSQL CHECK constraint `available_balance >= 0` is the last line
of defence, but the guard check described in Section 2.3 prevents the
negative balance from ever being attempted. The sequence is:

1. Lock the account row.
2. Read the current balance *while holding the lock*.
3. Compare balance >= amount.
4. On failure: insert a FAILED transaction record; no ledger or balance
   change. Release the lock via ROLLBACK or COMMIT.
5. On success: insert the transaction, both ledger lines, and both
   balance updates in the same transaction. COMMIT atomically.

Because all five steps run inside one database transaction with the lock
held throughout, no concurrent session can change the balance between
steps 2 and 5. Overdrafts and lost updates are impossible.

---

## 6. Rollback Correctness

PostgreSQL guarantees that a ROLLBACK undoes all DML statements in the
current transaction, including INSERTs into `transactions`,
`ledger_entries`, and `audit_logs`. The constraint `available_balance >= 0`
reinforces this at the database level: even if application code fails to
roll back, a negative-balance UPDATE would be rejected.

The deliberate rollback demo (Exercise B, `P3_CommitRollback.sql`) confirms:
- No transaction record with ref `TXN-P3-ROLLBACK-001` exists after rollback.
- No ledger entries exist for that ref.
- Both account balances are unchanged.

---

## 7. Idempotency and Duplicate Prevention

The `idempotency_keys` table has a unique constraint on `(scope, idem_key)`.
The posting path checks for an existing record before executing:

1. If no record exists: execute the transfer, insert the record, and commit.
2. If a record exists and the request hash matches: return the stored
   transaction ID without any new financial effect.
3. If a record exists and the request hash differs: reject with a conflict
   error — the key was already used for a different operation.

This makes every transfer endpoint safe to retry after a network timeout
or connection drop. The client will always receive the same financial
result for the same key, regardless of how many times it sends the request.

---

## 8. Evidence Checklist

| Exercise | Script | Key result to screenshot |
|---|---|---|
| A — Commit | `P3_CommitRollback.sql` step A3 | Before/after balances, ledger entries |
| B — Rollback | `P3_CommitRollback.sql` step B3 | Zero rows in transactions and ledger_entries |
| C — Insufficient funds | `P3_InsufficientFunds.sql` steps C3–C5 | FAILED status, zero ledger lines, balance unchanged |
| D — Reversal | `P3_Reversal.sql` steps D3–D5 | Original POSTED + reversal POSTED, four ledger entries |
| E — Idempotency | `P3_Idempotency.sql` steps E2–E4 | One posting count, conflict notice for TX-07 |
| F — Concurrency race | `P3_ConcurrencyTests.sql` Part 2 | Session B FAILED or POSTED depending on balance, no overdraft |
| G — Deadlock + safe fix | `P3_ConcurrencyTests.sql` Part 3 | Deadlock error from PostgreSQL; then clean run with ascending lock order |
| Reconciliation | `P3_ConcurrencyTests.sql` Part 4 | Drift column = 0 for all P3 demo accounts |
