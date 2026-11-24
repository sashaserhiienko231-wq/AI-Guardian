$ErrorActionPreference = "Stop"
$root = Resolve-Path "$PSScriptRoot\.."
$source = Join-Path $root "apps\mobile"
$stage = "F:\ai_guardian_windows_release"
New-Item -ItemType Directory -Force $stage | Out-Null
Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $stage | Out-Null

robocopy $source $stage /E /XD build .dart_tool android\.gradle android\build windows\flutter\ephemeral .idea
if ($LASTEXITCODE -gt 8) { throw "Failed to stage Windows project" }

Set-Location $stage
flutter clean
flutter pub get
flutter build windows --release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$release = Join-Path $stage "build\windows\x64\runner\Release"
$required = @(
    "ai_guardian.exe",
    "flutter_windows.dll",
    "file_selector_windows_plugin.dll",
    "data\app.so",
    "data\icudtl.dat"
)
foreach ($relative in $required) {
    $path = Join-Path $release $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required Windows release file is missing: $relative"
    }
}

$package = Join-Path $root "artifacts\windows\AI_Guardian_Windows_Release"
Remove-Item -Recurse -Force $package -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $package | Out-Null
Copy-Item -Recurse -Force "$release\*" $package

$exe = Join-Path $package "ai_guardian.exe"
$hash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
Write-Host "Windows package: $package"
Write-Host "Windows EXE SHA-256: $hash"
