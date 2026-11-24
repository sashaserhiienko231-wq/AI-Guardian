# Start Here

## Backend

```powershell
scripts\setup.ps1
scripts\start_backend.ps1
```

Open `http://127.0.0.1:8000/docs`.

## Web

```powershell
scripts\start_web.ps1
```

## Tests

```powershell
scripts\run_all_tests.ps1
```

## Builds

```powershell
scripts\build_android.ps1
scripts\build_windows.ps1
```

For production, copy `.env.example` to `.env`, set strong PostgreSQL credentials,
set `API_PRODUCTION=true`, and set a long random `API_AUTH_TOKEN`.
