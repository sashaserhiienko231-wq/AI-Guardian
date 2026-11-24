# Architecture

AI Guardian uses a FastAPI backend and a cross-platform Flutter application.

- UI: Material 3, Riverpod state, GoRouter navigation.
- API: versioned `/api/v1` endpoints.
- Data: SQLAlchemy with SQLite locally and PostgreSQL in Docker.
- Security: deterministic URL/email/QR rules, local password analysis, input limits, SSRF-free design.
- Learning: lesson and progress API.
- ML: optional TF-IDF and logistic-regression training pipeline, complementing deterministic rules.

## Frontend-to-backend flow

Flutter sends JSON requests to versioned `/api/v1` endpoints through Dio.
The backend validates Pydantic payloads, runs deterministic services, optionally
runs the trained ML classifier, persists only non-password scan history, and
returns explainable findings.

## API structure

- Health and scanner endpoints
- History and dashboard endpoints
- Assistant provider endpoint
- Learning and settings endpoints
- Optional bearer authentication for protected history/dashboard routes

## ML pipeline

External PhiUSIIL CSV data is preprocessed into URL-derived features.
Data is split 70/15/15 by a seeded stratified split. Logistic Regression is
trained on URL features and evaluated on validation/test sets. Inference uses
the same feature extractor and is explicitly probabilistic.

## AI providers

The local educational provider requires no network. Ollama and OpenAI use
environment configuration, request timeouts, provider-specific error handling,
and a rate limiter. Password values are never sent to providers.

## Storage

SQLite is used for local development. PostgreSQL is available through Docker.
ScanHistory stores identifiers, scan type, score, category, sanitized indicators,
summary, and UTC timestamp. Passwords and email bodies are not persisted.

## Protection layers

- Pydantic input limits
- URL scheme and hostname validation
- Private/reserved IP and DNS address rejection
- Request-size and API-rate limits
- Optional production bearer token
- SQLAlchemy parameterized database access
- Generic server error responses
