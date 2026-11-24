$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path "$PSScriptRoot\..")
python --version
python -m pip install -r backend/requirements.txt
Set-Location apps/mobile
flutter pub get
