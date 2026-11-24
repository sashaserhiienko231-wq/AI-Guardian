# Security

- Password analysis is entirely local in Flutter. Password values are never sent or persisted.
- Email bodies are not persisted.
- The backend does not fetch arbitrary URLs. URL analysis parses the supplied text only.
- HTTP URLs are penalized; HTTPS is not treated as proof of legitimacy.
- QR content is previewed and must be confirmed by the user before opening.
- SQLite local development and PostgreSQL production use SQLAlchemy parameterization.
- CORS and request limits must be reviewed before public deployment.
- Optional `API_AUTH_TOKEN` protects history, export, detail, delete, and dashboard endpoints.
- Docker Compose binds the backend to loopback.
- Database credentials are supplied through environment variables.
- URL validation rejects credentials, unsupported schemes, localhost, private,
  loopback, link-local/reserved IP addresses, and nonstandard ports.
- DNS resolution is checked for restricted resolved addresses.
- The backend does not fetch or redirect-follow arbitrary user URLs.
- Request bodies are limited to 1 MiB and API/AI rate limits are enforced.
- Security headers include CSP, frame denial, no-sniff, and referrer restrictions.
