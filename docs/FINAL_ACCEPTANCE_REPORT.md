# AI Guardian Final Acceptance Report

## Test execution summary

- Backend: 40 tests passed, 0 failed.
- Flutter analyze: no issues.
- Flutter widget test: 1 passed, 0 failed.
- Web production build: passed after a clean rebuild.
- Windows release build: passed via ASCII staging path.
- Android release build: passed via F-drive staging and fresh Gradle cache.
- Android APK Signature Scheme v2: verified.
- Password backend endpoint: removed; 404 confirmed.
- Root `/health` and `/ready`: verified over HTTP.
- ML `/api/v1/scanner/url/ml`: verified over HTTP.
- Provider discovery: verified; local provider active.

## Function status

| Function | Implemented | Starts | Verified | Limitation |
| --- | --- | --- | --- | --- |
| FastAPI backend | Yes | Yes | PASSED | External database unavailable locally |
| SQLite | Yes | Yes | PASSED | No live corruption recovery simulation |
| PostgreSQL | Configured | Docker not run | NOT TESTED | Docker unavailable |
| URL scanner | Yes | Yes | PASSED | No live redirect fetching |
| ML inference | Yes | Yes | PASSED | Dataset-specific predictions |
| Email Guardian | Yes | Yes | PASSED | SMTP header input is optional |
| QR API | Yes | Yes | PASSED | Camera hardware not tested |
| QR Flutter | Yes | Yes | PARTIALLY VERIFIED | Camera untested |
| Password security | Local only | Yes | PASSED | Backend endpoint removed |
| Local AI | Yes | Yes | PASSED | Rule-based educational replies |
| Ollama | Configured | Not run | NOT TESTED | Ollama server/model required |
| OpenAI | Configured | Not run | NOT TESTED | API key required |
| History | Yes | Yes | PASSED | Shared guest/local mode |
| Dashboard | Yes | Yes | PASSED | Data derived from stored scans |

## Platform status

- Android installation: NOT TESTED — no physical device/ADB device.
- Android release build: PASSED.
- Windows runtime: PARTIALLY VERIFIED — build passed; GUI untested.
- Web runtime: PASSED — build and widget test; camera untested.
- Camera hardware: NOT TESTED.
- PostgreSQL runtime: NOT TESTED — Docker CLI unavailable.
- Ollama runtime: NOT TESTED — service unavailable.
- OpenAI runtime: NOT TESTED — API key unavailable.
- Offline mode: PASSED — backend health, local assistant, and local dashboard tested.

## Remaining limitations

- The ML model may misclassify URLs and is never presented as a confirmed threat.
- No live reputation provider or redirect fetch is integrated.
- The Android release uses an Android debug signing certificate.
- PostgreSQL and external AI providers require deployment-specific secrets/services.
- Physical camera and GUI runtime require hardware/manual testing.
