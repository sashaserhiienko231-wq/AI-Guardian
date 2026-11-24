$ErrorActionPreference = "Stop"
$root = Resolve-Path "$PSScriptRoot\.."
Push-Location "$root\backend"
python -m pytest -q
if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }
Pop-Location
Push-Location "$root\apps\mobile"
flutter analyze
if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }
flutter test
if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }
Pop-Location
