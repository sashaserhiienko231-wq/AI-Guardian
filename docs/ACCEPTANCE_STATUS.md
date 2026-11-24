# Final Acceptance Status

| Component | Status | Confirmation |
| --- | --- | --- |
| Backend | PASSED | 35 backend tests passed |
| Authentication | PASSED | Guest mode and production token tests |
| PostgreSQL | NOT TESTED | Docker CLI unavailable; configuration inspected |
| ML | PARTIALLY VERIFIED | Loading and inference passed; metrics unchanged |
| QR Scanner | PARTIALLY VERIFIED | Backend and Flutter verified |
| AI Providers | PARTIALLY VERIFIED | Local tests passed; services untested |
| Android | PARTIALLY VERIFIED | APK and v2 signature verified |
| Windows | PASSED | Executable rebuilt; SHA-256 recorded |
| Web | PASSED | Production build, analyzer, and widget test passed |
| Offline Mode | PASSED | Local health, assistant, and dashboard verified |

## Known limits

- Shared bearer token is demonstration configuration, not complete user identity.
- No production signing keystore is included.
- Camera and physical install checks require hardware.
- ML probabilities are not confirmed threats.
