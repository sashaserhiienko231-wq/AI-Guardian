# AI Guardian Release Notes

## 2.0.0

### Included

- URL, email, QR, password, AI, history, dashboard, and ML features
- SQLite local mode and PostgreSQL Compose configuration
- Environment-based Android production signing
- SSRF/private-network protection and request limiting

### Signing status

- No production keystore or signing secret is included.
- Release signing fails closed when secrets or the keystore are absent.
- Debug builds use the Android debug certificate.
- Setup instructions: `docs/ANDROID_KEYSTORE_SETUP.md`.

### Production APK status

NOT CREATED. A production keystore was not authorized or supplied.

Run `scripts\build_android_production.ps1` after configuring local signing variables.

### Known release requirements

- Physical Android installation and camera hardware testing
- Production signing verification
- Google Play policy and publishing checks
- Live PostgreSQL, Ollama, OpenAI, and reputation-provider testing
