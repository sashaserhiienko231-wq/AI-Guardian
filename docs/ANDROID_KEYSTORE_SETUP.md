# Android production keystore setup

No keystore or signing secret is included in this repository.

## Create a private keystore

Run in a trusted environment and keep the keystore outside the source tree:

```powershell
keytool -genkeypair -v `
  -keystore F:\secure\ai_guardian_upload.jks `
  -alias ai_guardian_upload `
  -keyalg RSA `
  -keysize 4096 `
  -validity 10000
```

Do not include passwords, private-key material, or the keystore itself in source
control, chat, screenshots, terminal output, or documentation.

## Environment configuration

Set four local environment variables in the build process:

```powershell
$env:AI_GUARDIAN_KEYSTORE='F:\secure\ai_guardian_upload.jks'
$env:AI_GUARDIAN_STORE_PASSWORD='<local-store-password>'
$env:AI_GUARDIAN_KEY_ALIAS='ai_guardian_upload'
$env:AI_GUARDIAN_KEY_PASSWORD='<local-key-password>'
```

Environment variables take precedence over the optional protected property file.

## Protected properties file

An optional `apps/mobile/android/key.properties` file may contain:

```text
storeFile=F:\\secure\\ai_guardian_upload.jks
storePassword=<local-store-password>
keyAlias=ai_guardian_upload
keyPassword=<local-key-password>
```

`android/key.properties` and `*.jks`/`*.keystore` are excluded by `.gitignore`.

## Build

```powershell
scripts\build_android_production.ps1
```

The script stages the project, requires a real keystore, builds a release APK,
and copies it to `artifacts/android/production/ai_guardian-v2-production.apk`.

## Verify

```powershell
java -jar "$env:ANDROID_HOME\build-tools\36.1.0\lib\apksigner.jar" verify --verbose --print-certs `
  artifacts\android\production\ai_guardian-v2-production.apk
```

Debug builds remain separate and continue using the Android debug certificate.
