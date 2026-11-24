# GitHub Publication Report

## Repository

- GitHub repository URL: [AI-Guardian](https://github.com/sashaserhiienko231-wq/AI-Guardian)
- Repository name: AI-Guardian
- Visibility: PUBLIC
- Default branch: main
- Initial commit: `0020cb74fd2d9dbaff802ebb16b0c2a83d11ccd7`
- Publication commit: `ef9c1c7a7fa95ce4d44f4e89d61a316a1810b79f`
- Tracked files: 197

## Publication status

- Status: PASSED
- Repository creation: PASSED
- Source push to `origin/main`: PASSED
- Remote tracking: `main` tracks `origin/main`
- Public repository page: PASSED through unauthenticated HTTP verification
- README availability: PASSED through the unauthenticated raw GitHub URL
- Source availability: PASSED through the unauthenticated raw GitHub URL
- Repository description: PASSED
- GitHub topics: PASSED

## GitHub Actions

- Workflow: CI
- Workflow path: `.github/workflows/ci.yml`
- Workflow state: active
- Initial push run: FAILED
- Initial failure causes:
  - Existing Markdown files exceeded strict default lint rules
  - Flutter CI used the moving stable SDK and found a newer SDK deprecation
  - Gitleaks lacked full history and could not resolve the push revision range
- CI configuration fixes:
  - Repository Markdown lint configuration added
  - Flutter pinned to version 3.41.5
  - Checkout configured with `fetch-depth: 0` for Flutter and Gitleaks jobs
- Rerun status: PASSED
- Rerun URL: [GitHub Actions run 45405125069](https://github.com/sashaserhiienko231-wq/AI-Guardian/actions/runs/45405125069)
- Rerun result: success
- Final push run: [GitHub Actions run 45405594007](https://github.com/sashaserhiienko231-wq/AI-Guardian/actions/runs/45405594007)
- Final push run result: PASSED

## Secret and signing audit

- Status: PASSED
- Staged credential patterns: NOT FOUND
- Environment, database, keystore, key-property, and credential files:
  NOT PRESENT
- `.env.example`: PRESENT as a placeholder-only template
- Android keystore and production signing credentials: EXCLUDED
- Local Android SDK configuration: EXCLUDED
- Local SQLite database: EXCLUDED
- Git history: no previous history existed before initialization

## Validation

- Backend pytest: PASSED, 40 tests passed
- Flutter analyze: PASSED with Flutter 3.41.5
- Flutter test: PASSED, 1 test passed
- Markdown lint: PASSED after repository configuration
- Git diff whitespace check: PASSED
- Documentation availability: PASSED through public GitHub
- Release: NOT CREATED
- Docker/PostgreSQL runtime: NOT TESTED
- Physical Android install: NOT TESTED
- Camera hardware: NOT TESTED

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

- The machine has no production keystore or authorized signing credentials.
- Release artifacts are excluded and require separate verification.
- Hardware-dependent Android camera and physical-device checks were not run.
- Docker/PostgreSQL runtime was not verified.
- GitHub Actions rerun verification is pending the fix commit.
