# Implementation Gap Report

## Verified implemented

- FastAPI health and readiness endpoints
- SQLite local database
- URL, email, QR, and local password logic
- ML model loading and inference endpoint
- Local, Ollama, and OpenAI provider abstraction
- History CRUD/export/search/sorting
- Flutter navigation and responsive dark UI
- Android, Windows, and Web build configuration
- Security middleware and optional bearer authorization

## Partial or external

- PostgreSQL runtime requires Docker or a local PostgreSQL installation.
- Docker Compose runtime was not executed in this environment.
- Ollama runtime requires an installed Ollama server and model.
- OpenAI runtime requires an API key and network access.
- Camera hardware is platform/hardware dependent.
- Android physical install requires a connected device.
- Windows camera runtime requires a Windows camera backend and device.

## Not retained

No password endpoint is retained in the backend. Password checks remain local in
the Flutter application and are not sent or persisted.
