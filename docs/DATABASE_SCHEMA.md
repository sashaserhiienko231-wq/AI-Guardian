# Database Schema

The initial implementation persists `ScanHistory` with UUID primary keys and UTC
timestamps. Planned and documented schema groups include users, security reports,
threat indicators, learning progress, quiz results, user settings, and audit events.

Scan history fields:
- `id`: UUID text primary key
- `scan_type`: URL, email, QR, or password
- `risk_score`: integer 0-100
- `risk_category`: Safe, Low, Medium, High, or Critical
- `indicators`: JSON list
- `summary`: short sanitized summary
- `created_at`: UTC timestamp
