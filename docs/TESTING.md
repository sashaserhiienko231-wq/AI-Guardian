# Testing

Backend:

```powershell
cd backend
python -m pytest -q
```

Flutter:

```powershell
cd apps/mobile
flutter analyze
flutter test
flutter build web
```

Actual validation recorded for this workspace:
- Backend: 12 tests passed.
- Flutter analysis: no issues.
- Flutter widget test: 1 test passed.
- Flutter Web: production build succeeded.
