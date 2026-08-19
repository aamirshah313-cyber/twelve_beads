# Android Compatibility, Performance, Security, and Release

## Android strategy

Use the current stable Flutter/Android Gradle toolchain at implementation time. Select a broad `minSdk` compatible with supported Flutter plugins (normally API 23 or lower only if verified), and the current Google Play-required `targetSdk`/`compileSdk` at release time. Record exact decisions in README and CI. Test API 23/24-era device profile, a current Android profile, small phone, large phone/tablet, portrait/landscape, and low-memory behavior.

Build a universal debug APK for easy QA; publish an Android App Bundle (preferred by Play) with ABI splits/delivery for `arm64-v8a`, `armeabi-v7a`, and `x86_64` where emulator distribution requires it. Verify native/plugin ABI compatibility. Keep APK size controlled by optimizing assets and avoiding a 3D engine.

## Release validation

- `flutter analyze`, formatting, unit/widget/integration suites, and release build must pass in CI.
- Build `--release` APK/AAB, install on a clean emulator/device, validate cold start, offline start, language switch, saved-game restore, timer lifecycle, AI and accessibility.
- Test R8/shrinking effects, Android 13+ notification behavior only if notifications are ever added, app signing, versionCode/versionName, and release notes.
- Validate no unintended permissions in the merged manifest and no network calls during offline test.
- Profile opponent-move playback on the low-memory/low-end device profile: moves, captures and chained captures must remain responsive, cancellable and understandable with adaptive quality enabled.

## Security/reliability

No secrets in app/source. Validate all persisted data on read and discard/recover malformed saved games safely. Guard integer/time overflow and lifecycle races. Do not trust client-side “history” as competitive proof; this is a local casual game. Provide crash-safe database transactions around match finalization.
