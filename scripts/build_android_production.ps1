$ErrorActionPreference = "Stop"

$root = Resolve-Path "$PSScriptRoot\.."
$source = Join-Path $root "apps\mobile"
$stage = "F:\ai_guardian_production_release"
$gradleHome = "F:\ai_guardian_gradle"
$tmp = "F:\ai_guardian_tmp"

New-Item -ItemType Directory -Force $stage,$gradleHome,$tmp | Out-Null

$propertyFile = Join-Path $source "android\key.properties"
$environmentMode = $true
foreach ($name in @(
    "AI_GUARDIAN_KEYSTORE",
    "AI_GUARDIAN_STORE_PASSWORD",
    "AI_GUARDIAN_KEY_ALIAS",
    "AI_GUARDIAN_KEY_PASSWORD"
)) {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($name))) {
        $environmentMode = $false
        break
    }
}

if (-not $environmentMode) {
    if (-not (Test-Path -LiteralPath $propertyFile -PathType Leaf)) {
        throw "Production signing is not configured. Set four AI_GUARDIAN_* environment variables or provide android/key.properties."
    }
    $properties = @{}
    Get-Content -LiteralPath $propertyFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#")) {
            $separator = $line.IndexOf("=")
            if ($separator -gt 0) {
                $properties[$line.Substring(0, $separator).Trim()] = $line.Substring($separator + 1).Trim()
            }
        }
    }
    foreach ($name in @("storeFile","storePassword","keyAlias","keyPassword")) {
        if ([string]::IsNullOrWhiteSpace($properties[$name])) {
            throw "android/key.properties is missing a required setting."
        }
    }
    $env:AI_GUARDIAN_KEYSTORE = $properties["storeFile"]
    $env:AI_GUARDIAN_STORE_PASSWORD = $properties["storePassword"]
    $env:AI_GUARDIAN_KEY_ALIAS = $properties["keyAlias"]
    $env:AI_GUARDIAN_KEY_PASSWORD = $properties["keyPassword"]
}

$keystore = [Environment]::GetEnvironmentVariable("AI_GUARDIAN_KEYSTORE")
if (-not (Test-Path -LiteralPath $keystore -PathType Leaf)) {
    throw "Configured production keystore was not found."
}
Remove-Item -Recurse -Force $stage -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $stage | Out-Null
robocopy $source $stage /E /XD build .dart_tool android\.gradle android\build windows\flutter\ephemeral .idea
if ($LASTEXITCODE -gt 8) { throw "Failed to stage Android project" }

Set-Location $stage
$env:GRADLE_USER_HOME = $gradleHome
$env:TEMP = $tmp
$env:TMP = $tmp

flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
flutter build apk --release --no-pub
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$artifactDir = Join-Path $root "artifacts\android\production"
New-Item -ItemType Directory -Force $artifactDir | Out-Null
$output = Join-Path $artifactDir "ai_guardian-v2-production.apk"
Copy-Item -Force "$stage\build\app\outputs\flutter-apk\app-release.apk" $output
Write-Host "Production APK staged at $output"
