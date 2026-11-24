$ErrorActionPreference = "Stop"
$root = Resolve-Path "$PSScriptRoot\.."
$source = Join-Path $root "apps\mobile"
$stage = "F:\ai_guardian_android_release"
$gradleHome = "F:\ai_guardian_gradle"
$tmp = "F:\ai_guardian_tmp"
New-Item -ItemType Directory -Force $stage,$gradleHome,$tmp | Out-Null
Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $stage | Out-Null
robocopy $source $stage /E /XD build .dart_tool android\.gradle android\build windows\flutter\ephemeral .idea
if ($LASTEXITCODE -gt 8) { throw "Failed to stage Android project" }
Set-Location $stage
$env:GRADLE_USER_HOME = $gradleHome
$env:TEMP = $tmp
$env:TMP = $tmp
flutter pub get
flutter build apk --debug --no-pub
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$artifactDir = Join-Path $root "artifacts\android\debug"
New-Item -ItemType Directory -Force $artifactDir | Out-Null
Copy-Item -Force "$stage\build\app\outputs\flutter-apk\app-debug.apk" "$artifactDir\ai_guardian-v2-debug.apk"
