# Build status

Environment validation:

- Backend: 40 tests passed after health/ready/provider/ML integrity additions.
- Security suite covers SSRF, auth, AI failure, privacy, and ML loading.
- Flutter analysis: no issues.
- Flutter widget test: passed.
- Web build: succeeded at `apps/mobile/build/web`.
- Windows 2.0 build: succeeded from an ASCII staging path; executable copied to
  `artifacts/windows/ai_guardian-v2-release.exe`.
- Windows SHA-256: `86AADE10397B47DBE14F79DD66F5B84A2E0D825B768BD629CDE644EE3602C7A5`.
- Android debug 2.0 APK: succeeded with a fresh Gradle home; APK copied to
  `artifacts/android/ai_guardian-v2-debug.apk`.
- Android release 2.0 APK: built successfully; size 67,661,458 bytes.
- APK SHA-256: `B2916BDDAAA6B0D0D067CA55EA5AAFFD81BB69D64D5849118E11EE50BC2F8AA4`.
- APK signature: verified with APK Signature Scheme v2 using Android debug certificate.
- Production signing: configured in Gradle to fail closed for release tasks.
- Debug signing: verified with Android debug certificate.
- Production signing runbook: `docs/ANDROID_KEYSTORE_SETUP.md`.
- Production keystore absent; no production APK or secret was created.
- Separate debug APK: built and signature-verified using Android debug certificate.
- Debug APK SHA-256: `75D68B6BCA75C4A041659A995A9500CE674425C9BE731AC71942C0FCC4476CE3`.
- No Android device was connected, so physical install could not be executed.
- Docker CLI unavailable, so Compose and live PostgreSQL were not executed.
- Windows package: `artifacts/windows/AI_Guardian_Windows_Release`.
- Packaged EXE SHA-256:
  `A2B280DCF887A9F46E8548F0FA9A3FAAE5105F749674C37E9A855106582CCA0C`.
- Package includes `ai_guardian.exe`, `flutter_windows.dll`,
  `file_selector_windows_plugin.dll`, `data/app.so`, `data/icudtl.dat`,
  and `data/flutter_assets`.
- Real launch: EXE remained running for 8 seconds with no missing-DLL error.
- File picker: NOT TESTED interactively.

No accuracy metric or test result is fabricated.
