# AI Guardian — Competition Presentation

## Problem

Students and everyday users face phishing links, misleading QR codes, fraudulent
email requests, weak passwords, and social-engineering attempts. Existing tools
often provide opaque scores or require external services.

## Goal

Provide an understandable, privacy-aware, cross-platform security assistant that
combines explainable rules, URL features, QR analysis, educational content, and
an optional probabilistic ML model.

## Core capabilities

- Explainable URL analysis
- Email and message phishing indicators
- QR content classification with UNKNOWN fail-safe
- Local password assessment
- AI assistant with local, Ollama, and OpenAI providers
- Persistent local scan history
- Search, filtering, sorting, and report export
- Dashboard statistics
- Ukrainian and English interface

## Target audience

Students, families, and everyday users who need understandable security
guidance without an advanced cybersecurity background.

## Architecture

- Flutter Android, Windows, and Web client
- Riverpod state management and GoRouter navigation
- FastAPI versioned REST backend
- SQLite local database or PostgreSQL server database
- SQLAlchemy repositories and Alembic migration support
- Scikit-learn URL classifier
- Provider abstraction for AI assistants

## Security

AI Guardian blocks restricted URL targets, validates hostnames and DNS results,
does not follow redirects, limits request size and rates, protects history in
production, and keeps password analysis on-device.

## ML

The PhiUSIIL UCI dataset (ID 967, CC BY 4.0) was used for real training.
Published metrics are historical test metrics and do not prove universal
phishing recognition.

## Difference from a basic scanner

The system combines deterministic findings with ML probabilities, separates
verified indicators from probabilistic predictions, and explains recommendations
instead of presenting a single opaque verdict.

## Limitations

- No live threat-reputation provider is configured.
- ML is dataset-specific.
- A production keystore is not supplied.
- Camera availability depends on platform permission and hardware.
- External AI providers require configuration and network access.

## Future development

- Production authentication and per-user history
- Live reputation and DNS integrations
- Privacy-preserving breach lookup
- Locally trained and versioned models
- Full SMTP header verification
- Camera hardware regression testing
