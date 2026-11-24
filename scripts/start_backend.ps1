$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path "$PSScriptRoot\..\backend")
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
