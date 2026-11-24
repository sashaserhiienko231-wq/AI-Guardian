# AI Guardian

AI Guardian is a cross-platform cybersecurity application that provides URL,
QR, email, and password safety analysis through a Flutter client and FastAPI
backend.

> [!WARNING]
> AI Guardian is a security assistance tool. It cannot guarantee detection of
> all phishing attacks or malicious content.

## Features

- URL analysis with heuristic indicators, SSRF protection, and trained ML inference
- QR preview, live mobile/web scanning, image fallback, and unknown safety state
- Email text analysis
- Optional Gmail add-on for user-triggered scanning of the currently open message
- On-device password strength analysis
- Manual, read-only Windows process check for processes running from Temp or Downloads folders
- AI assistant integration for local/Ollama or OpenAI providers
- Scan history, search, details, deletion, and export
- SQLite development database and PostgreSQL production support
- Optional bearer authentication for protected backend endpoints

## Supported platforms

- Android
- Windows
- Web
- Flutter source support for additional platforms is present, but CI is currently
  focused on the tested Android, Windows, and web workflows

The process check is available only in the Windows desktop app. It uses a
location heuristic, may flag legitimate software, and is not a full malware
scanner or a guarantee that a process is malicious or safe.

The Gmail add-on is optional and user-triggered; it does not monitor the inbox.
See [Gmail add-on setup](docs/GMAIL_ADDON_SETUP.md) for deployment and privacy
details.

## Technology stack

- Flutter and Dart
- FastAPI and Pydantic
- SQLAlchemy, SQLite, and PostgreSQL
- scikit-learn and joblib
- Docker and Docker Compose
- GitHub Actions

## Architecture

The Flutter application communicates with the FastAPI backend. The backend
validates and analyzes user-provided content, persists scan metadata, and
serves trained URL model predictions separately from heuristic results.

```text
Flutter client
  -> FastAPI API
  -> Security analysis + ML inference
  -> SQLite (development) or PostgreSQL (production)
```

See [Architecture](docs/ARCHITECTURE.md) and
[API documentation](docs/API_DOCUMENTATION.md).

## Machine Learning

AI Guardian includes a Logistic Regression URL classifier trained on the
PhiUSIIL phishing URL dataset. The test metrics in
[the model card](docs/ML_MODEL_CARD.md) are obtained on a specific PhiUSIIL test
split. They do not guarantee performance on every real-world or newly observed
population.

The ML prediction is probabilistic and is not a confirmed malware verdict.
Dataset attribution and license details are in
[Dataset Sources](docs/DATASET_SOURCES.md). PhiUSIIL is CC BY 4.0; this dataset
license does not license the AI Guardian application itself.

## Security

- URL credentials and unsupported schemes are rejected
- Private, loopback, link-local, reserved, and nonstandard destinations are rejected
- DNS resolution is checked before URL analysis
- Arbitrary URL fetching and redirect following are not implemented
- Passwords are assessed locally and are not sent to the backend
- Optional API bearer authorization and request/AI rate limits are enforced
- Security headers and CORS settings are configurable

Read [Security](docs/SECURITY.md) and
[Security Review](SECURITY-REVIEW.md).

## Backend setup

```powershell
cd backend
python -m pip install -r requirements.txt
Copy-Item ..\.env.example ..\.env
python -m uvicorn app.main:app --reload --port 8000
```

API documentation is available at `http://localhost:8000/docs`.

## Flutter setup

```powershell
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

The committed `pubspec.lock` should be used for reproducible application builds.

## Android build

```powershell
cd apps/mobile
flutter build apk --release
```

Production signing is environment-based and no signing keystore is committed.
Follow [Android keystore setup](docs/ANDROID_KEYSTORE_SETUP.md).

## Windows build

```powershell
cd apps/mobile
flutter build windows --release
```

Use the complete generated release directory rather than a standalone executable;
the executable depends on runtime DLLs and Flutter assets.

## Web build

```powershell
cd apps/mobile
flutter build web --release
```

## Docker

Copy [.env.example](.env.example) to `.env`, set a random database password and
API token, then run:

```powershell
docker compose up --build
```

The backend is bound to loopback in the provided Compose configuration.

## PostgreSQL

Set these variables before starting Docker Compose:

- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `DATABASE_URL`

The Compose file derives the database URL from the PostgreSQL environment values.
Do not commit real credentials.

## Ollama

Set `AI_PROVIDER=ollama`, `OLLAMA_BASE_URL`, and `OLLAMA_MODEL`.
The default configuration does not require a secret.

## OpenAI

Set `AI_PROVIDER=openai` and `OPENAI_API_KEY` only in a local environment or
deployment secret store. Never commit an API key.

## Environment variables

The complete safe template is [.env.example](.env.example). Android production
signing variables are documented in
[Android keystore setup](docs/ANDROID_KEYSTORE_SETUP.md).

## Testing

```powershell
cd backend
python -m pytest -q

cd ..\apps\mobile
flutter analyze
flutter test
```

Existing test and build evidence is summarized in
[Test Report](docs/TEST_REPORT.md) and [Testing](docs/TESTING.md).

## Screenshots

No verified public screenshots are included yet. Add screenshots only after
reviewing them for personal data, secrets, and environment-specific identifiers.

## Project structure

```text
backend/                  FastAPI application, ML, and tests
apps/mobile/              Flutter application
artifacts/                Locally built release artifacts
docs/                     Project documentation
scripts/                  Setup and build scripts
docker-compose.yml        Backend and PostgreSQL services
Dockerfile                Backend container
.github/workflows/ci.yml  Automated checks
```

## Documentation

- [Acceptance Status](docs/ACCEPTANCE_STATUS.md)
- [AI Disclosure](docs/AI_DISCLOSURE.md)
- [Android Keystore Setup](docs/ANDROID_KEYSTORE_SETUP.md)
- [API Documentation](docs/API_DOCUMENTATION.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Build Status](docs/BUILD_STATUS.md)
- [Changelog](docs/CHANGELOG.md)
- [Competition Presentation](docs/COMPETITION_PRESENTATION.md)
- [Contributing](docs/CONTRIBUTING.md)
- [Database Schema](docs/DATABASE_SCHEMA.md)
- [Dataset Sources](docs/DATASET_SOURCES.md)
- [Demo Scenario](docs/DEMO_SCENARIO.md)
- [Final Acceptance Report](docs/FINAL_ACCEPTANCE_REPORT.md)
- [Implementation Gap Report](docs/IMPLEMENTATION_GAP_REPORT.md)
- [Installation](docs/INSTALLATION.md)
- [ML Documentation](docs/ML_DOCUMENTATION.md)
- [ML Model Card](docs/ML_MODEL_CARD.md)
- [Privacy](docs/PRIVACY.md)
- [Privacy Policy](docs/PRIVACY_POLICY.md)
- [Release Notes](docs/RELEASE_NOTES.md)
- [Security](docs/SECURITY.md)
- [Start Here](docs/START_HERE.md)
- [Test Report](docs/TEST_REPORT.md)
- [Testing](docs/TESTING.md)

## Known limitations

- Not every real-world phishing attack can be detected
- ML metrics are limited to a documented test split
- Production APK signing requires a separately managed keystore
- Physical camera, Android device, and Docker/PostgreSQL runtime validation may
  require hardware or infrastructure not available in CI

## Roadmap

- Broader independent evaluation datasets
- Additional provider integrations
- Signed and reproducible release artifacts
- Expanded end-to-end and hardware tests
- Improved privacy-preserving telemetry

## License

A repository-level application license has not yet been selected. No license
is granted merely by making the source available. The PhiUSIIL dataset is
separate and is used under CC BY 4.0 with attribution in the project
documentation.
