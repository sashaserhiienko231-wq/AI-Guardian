# AI Guardian Security Review

## Findings summary

| # | Severity | File | Lines | Vulnerability | Confidence |
|---|----------|------|-------|---------------|------------|
| 1 | 🟡 MEDIUM | backend/app/api/v1/routes.py | 128-199 | Unrestricted history and dashboard access | 10/10 |
| 2 | 🟡 MEDIUM | docker-compose.yml | 7-16 | Hardcoded PostgreSQL credentials | 9/10 |

## Resolved

1. History, export, detail, deletion, and dashboard endpoints now support optional
   `API_AUTH_TOKEN` bearer authorization. Guest mode remains available only when the
   token is not configured.
2. Docker Compose no longer embeds database credentials. PostgreSQL variables are
   required from environment configuration.
3. Backend binding is loopback-only in Docker.
4. URL validation rejects credentials, unsupported schemes, localhost, private,
   loopback, link-local, reserved IP addresses, and nonstandard HTTP ports.
5. DNS resolution is checked and restricted addresses are rejected.
6. Arbitrary URL fetching is not implemented; redirect links are analyzed only as
   text and are not followed.
7. Request body size, API and AI rate limits, security headers, CORS, and generic
   500 responses were hardened.
8. Password assessment remains local in Flutter and has no password history API.
9. Production mode now fails closed if `API_AUTH_TOKEN` is missing.
10. Flutter supports a build-time `API_AUTH_TOKEN` header for protected API access.
