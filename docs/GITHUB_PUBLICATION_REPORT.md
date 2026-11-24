# GitHub Publication Report

## Repository

- GitHub repository URL: NOT CREATED
- Repository name: AI-Guardian
- Visibility: NOT PUBLISHED
- Default branch: main
- Commit hash: `0020cb74fd2d9dbaff802ebb16b0c2a83d11ccd7`
- Committed files: 195

## Publication status

GitHub publication was blocked because GitHub CLI authentication did not
complete. No repository was created and no source code was pushed.

## Secret and signing audit

- Status: PASSED
- Staged credential patterns: NOT FOUND
- Staged environment, database, keystore, key-property, and credential files:
  NOT PRESENT
- `.env.example`: PRESENT as a placeholder-only template
- Android keystore and production signing credentials: EXCLUDED
- Local Android SDK configuration: EXCLUDED
- Local SQLite database: EXCLUDED
- Existing Git history: NOT APPLICABLE; this repository was newly initialized

## Validation

- Backend pytest: PASSED, 40 tests passed
- Flutter analyze: PASSED, no issues found
- Flutter test: PASSED, 1 test passed
- Markdown lint: PARTIALLY VERIFIED
- Git diff whitespace check: PASSED
- GitHub Actions: NOT TESTED; workflow created but not run before publication
- README availability: NOT TESTED; repository not published
- Documentation availability: NOT TESTED; repository not published
- Public visibility: NOT TESTED; repository not published
- Release: NOT CREATED

## Excluded files

- `.env` and `.env.*`, except `.env.example`
- `secrets/` and `credentials/`
- `*.jks` and `*.keystore`
- `key.properties` and Android `local.properties`
- `*.db`, `*.sqlite`, and `*.sqlite3`
- Flutter build and `.dart_tool` directories
- Android `.gradle` and build directories
- Python caches and virtual environments
- IDE configuration directories
- APK, AAB, and `artifacts/` build output

## Known limitations

- GitHub authentication must be completed before repository creation or push.
- The machine has no production keystore or authorized signing credentials.
- Hardware-dependent Android camera and physical-device checks were not run.
- Docker/PostgreSQL runtime was not verified.
- Release artifacts are excluded from the initial commit and must be reviewed
  separately before any release publication.
