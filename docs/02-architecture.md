# System Architecture: AI-Powered Stock Portfolio Tool

## 1. Tech Stack & Justifications

*   **Backend:** **Python (FastAPI)**
    *   *Justification:* Chosen for its seamless integration with ML/AI libraries (FinBERT for NLP, scikit-learn/pandas for technical analysis). FastAPI provides high performance, out-of-the-box OpenAPI documentation, and asynchronous capabilities which are crucial for concurrent live market data fetching.
*   **Frontend:** **React (Vite) with Tailwind CSS and Recharts**
    *   *Justification:* React offers a component-driven architecture for complex dashboards. Vite ensures fast build times and a smooth developer experience. Recharts provides responsive, lightweight financial charting capabilities without the bloat of larger libraries.
*   **Database:** **SQLite**
    *   *Justification:* Selected per single-user/freemium initial specification. To meet financial data integrity requirements, SQLite will strictly use `INTEGER` types to store monetary values in cents and quantities multiplied by 10,000 to entirely eliminate floating-point rounding errors.
*   **Authentication & Security:** **JWT with MFA**
    *   *Justification:* Required for access control and regulatory constraints. Passwords will be hashed using Argon2.

## 2. Directory Structure

```text
/
├── backend/
│   ├── app/
│   │   ├── api/               # API routers (v1)
│   │   ├── core/              # Config, security, JWT auth, idempotency logic
│   │   ├── db/                # SQLite connection, migrations
│   │   ├── models/            # SQLAlchemy/Pydantic models
│   │   ├── services/          # Business logic, AI engine, integrations
│   │   │   ├── market_data/   # nsepython & yfinance wrappers
│   │   │   ├── analysis/      # FinBERT sentiment & tech indicators
│   │   └── utils/             # Helpers (decimal converters, audit logger)
│   ├── tests/                 # Pytest test suite
│   ├── requirements.txt
│   └── main.py                # FastAPI entry point
├── frontend/
│   ├── public/
│   ├── src/
│   │   ├── components/        # Reusable UI components
│   │   ├── pages/             # Dashboard, Portfolio, Watchlist
│   │   ├── services/          # API clients
│   │   ├── store/             # React Context / Zustand state management
│   │   └── utils/             # Formatters (currency, percentages)
│   ├── package.json
│   └── vite.config.js
├── docs/
│   ├── 01-market-requirements.md
│   ├── 02-architecture.md
│   ├── 02-api-contracts.json
│   └── 02-db-schema.sql
└── .gitignore
```

## 3. Core Architectural Strategies & Domain Constraints

### 3.1. Data Integrity (Decimal/Fixed-Point Arithmetic)
**Floating-point types are strictly forbidden for financial metrics.**
*   **Storage:** All monetary values are stored in the database as `INTEGER` representing the lowest denomination (e.g., cents, paise). Fractional shares are stored as `INTEGER` (scaled by 10,000).
*   **Processing:** The backend uses Python's `decimal.Decimal` module for any necessary intermediate calculations before saving to the DB.
*   **Transport:** APIs transmit monetary values as integers. The frontend converts these to formatted strings strictly for display purposes.

### 3.2. Security (Encryption & PCI-DSS/SOX Principles)
*   **Encryption in Transit:** Enforced TLS 1.3 for all client-server communication.
*   **Encryption at Rest:** Although SQLite is file-based, SQLCipher or filesystem-level encryption (e.g., LUKS, BitLocker) will be utilized to encrypt the database file.
*   **MFA:** Time-Based One-Time Password (TOTP) integration for administrative and user authentication.

### 3.3. Auditability (SOX-style Trails)
*   An `audit_logs` table automatically records every state change (`CREATE`, `UPDATE`, `DELETE`) on critical tables (like `portfolio_holdings`).
*   The log captures the `user_id`, `action`, `ip_address`, and a JSON diff of the old and new values.
*   These logs are append-only and explicitly designed for 7+ years of retention.

### 3.4. Transaction Processing (Idempotency)
*   Exactly-once semantics are enforced for state-mutating requests (e.g., adding a holding).
*   Clients must send an `Idempotency-Key` header.
*   The backend checks the `idempotency_keys` table. If a request is retried (e.g., due to network timeout), the server returns the cached response without processing the transaction again.

### 3.5. Rate Limiting & Fraud Detection
*   FastAPI rate limiters (e.g., `slowapi`) are applied globally to prevent abuse.
*   Live market data endpoints and the AI recommendation engine have strict per-user request quotas to protect underlying APIs (NewsAPI, yfinance).

### 3.6. Disaster Recovery
*   **Backup Strategy:** Automated cron jobs run frequent, encrypted snapshots of the SQLite database to remote object storage (e.g., AWS S3).
*   **RPO/RTO:** Continuous backup to meet RPO < 1 hour. Automated restore scripts ensure RTO < 4 hours.

## 4. Referenced Artifacts
*   **API Contracts:** [02-api-contracts.json](file:///C:/antigravity/trading/docs/02-api-contracts.json)
*   **Database Schema:** [02-db-schema.sql](file:///C:/antigravity/trading/docs/02-db-schema.sql)
