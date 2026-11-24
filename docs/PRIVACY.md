# Privacy

Password values are analyzed locally in Flutter and are not sent to the backend,
stored in SQLite/PostgreSQL, written to logs, or sent to AI providers.

Email bodies are accepted for analysis but are not persisted. Scan history stores
scan type, score, category, sanitized indicators, a short summary, and timestamp.

AI provider requests contain only the user's assistant message. API keys are read
from environment variables and must never be committed.
