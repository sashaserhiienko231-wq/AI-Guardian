# AI Guardian

AI Guardian is a Flutter security companion with URL, email, and QR checks,
local-only password pattern analysis, threat history, learning content, and a
read-only Windows process-path review. Ukrainian is the default interface
language; English is available in Settings.

## Run locally

The app connects to `http://localhost:8000` by default. To use another API
address, provide `--dart-define=API_BASE_URL=https://your-api.example` when
running or building the app.

```powershell
flutter pub get
flutter run -d windows
```

## Build for Windows

```powershell
flutter build windows --release
```

The self-contained Windows release directory is:

```text
build\windows\x64\runner\Release\
```

Run `ai_guardian.exe` from that directory so the Flutter runtime, plugins, and
assets beside it remain available.
