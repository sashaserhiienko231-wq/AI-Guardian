# Installation

## Backend

```powershell
cd backend
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --reload --port 8000
```

Open `http://localhost:8000/docs`.

## Flutter

```powershell
cd apps/mobile
flutter pub get
flutter run -d chrome
flutter run -d windows
flutter run
```

Set `--dart-define=API_BASE_URL=http://localhost:8000` when targeting a separate backend.

## Docker

```powershell
docker compose up --build
```
