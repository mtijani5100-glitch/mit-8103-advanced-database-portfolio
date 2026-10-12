# Environment and Technical Specifications

> **Course:** MIT 8103 Advanced Database Systems  
> **Project:** LedgerSpring Digital Bank (LSDB) Database Portfolio  
> **Repository:** `mit-8103-advanced-database-portfolio`

---

## 1. Operating System and Hardware

| Attribute | Specification |
|---|---|
| **Operating System** | macOS 26.4.1 (Darwin Kernel Version 25.2.0) |
| **Architecture** | ARM64 (`aarch64-apple-darwin25.2.0`) / Apple Silicon |
| **Compiler** | Apple clang version 17.0.0 (clang-1700.6.3.2), 64-bit |
| **Shell** | `zsh` 5.9 |

---

## 2. Relational Database (Primary System of Record)

| Component | Verified Specification |
|---|---|
| **DBMS Engine** | PostgreSQL 16.13 (Homebrew) |
| **PostgreSQL Build** | `PostgreSQL 16.13 (Homebrew) on aarch64-apple-darwin25.2.0, compiled by Apple clang version 17.0.0 (clang-1700.6.3.2), 64-bit` |
| **CLI Client** | `psql` (PostgreSQL) 16.13 (Homebrew) |
| **Database Name** | `ledgerspring` |
| **Default Encoding** | UTF-8 (`client_encoding = 'UTF8'`) |
| **Timezone Setting** | UTC (`TimeZone = 'UTC'`, timestamps stored as `TIMESTAMPTZ`) |
| **Port** | 5432 (standard PostgreSQL port) |

### Verification Command

To verify the local database engine and connection:

```bash
psql -d ledgerspring -c "SELECT version();"
psql --version
sw_vers
```

---

## 3. Supporting Tools and Software

| Category | Tool / Version | Purpose |
|---|---|---|
| **Version Control** | Git 2.39+ / GitHub (`mtijani5100-glitch/mit-8103-advanced-database-portfolio`) | Progressive portfolio tracking and commits |
| **ER Diagramming** | diagrams.net (draw.io) / Mermaid.js | Visual relational modelling (`diagrams/erd-v2.drawio`) |
| **NoSQL Database (Planned - Portfolio 4)** | MongoDB Community Edition 7.x / `mongosh` | Operational event projections & audit document storage |
| **Containerisation (Planned - Portfolio 5)** | Docker Desktop / Docker Compose | Local reproducible distributed topology demo |

---

## 4. Environment Variables & Security Practices

- **Configuration Template:** Standard connection strings use local socket authentication or environment variables (e.g., `PGDATABASE=ledgerspring`, `PGPORT=5432`).
- **Secrets Management:** In accordance with academic guidelines, no production credentials, real API tokens, or actual payment keys are committed. A template `.env.example` is maintained, and sensitive files are ignored via `.gitignore`.
- **Database Reset Capability:** The entire schema and test state can be cleanly reconstructed using:
  ```bash
  psql -d ledgerspring -f portfolio-1-database-design/sql/00_reset.sql
  psql -d ledgerspring -f portfolio-1-database-design/sql/01_create_schema.sql
  psql -d ledgerspring -f portfolio-1-database-design/sql/02_seed_data.sql
  psql -d ledgerspring -f portfolio-1-database-design/sql/03_constraint_tests.sql
  ```
