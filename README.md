# Twelve Beads / بارہ گوٹی

An offline, local-only Android board game in the Alquerque family, built with
Flutter. Two people can play pass-and-play on one device, or play against an
offline machine opponent with three difficulty levels. No accounts, no ads,
no analytics, and no internet permission — everything (settings, profile
stats, badges, match history, an in-progress match) stays on the device.

## Features

- Classic Alquerque rules on a 5×5 board (25 junctions, 12 beads/side),
  procedurally rendered — never a static image asset — with mandatory
  capture and mandatory chain-capture continuation.
- Local two-player pass-and-play, with optional per-player chess-clock
  timers (fixed presets or a custom value) and an independent optional
  per-move timer, each with a low-time warning cue (visual + haptic +
  the stubbed sound cue).
- Offline machine opponent: Easy (random legal move), Medium (fixed-depth
  search), Difficult (iterative-deepening search with alpha-beta pruning and
  a bounded time budget) — all three only ever consult the same
  `legalActions`/`apply` the human player is bound by.
- A shared move-presentation timeline for both human and machine moves:
  source/travel/capture/destination cues, played step by step through a
  capture chain, with TalkBack announcements and haptics.
- Full English and Urdu localization, including right-to-left layout for
  Urdu (the board's own grid deliberately stays fixed regardless of
  language — see `docs/spec/DECISIONS.md`).
- Accessibility: TalkBack-labeled board nodes (owner, state, and position),
  a tri-state reduced-motion preference, a high-contrast mode that reaches
  the board's own bead colors, and non-color-only visual cues throughout
  (shape, not just color, for legal moves/captures/selection/etc.).
- Local quick chat: a small set of preset phrases ("Good move", "Your
  turn", ...) shown as a transient, auto-dismissing overlay during a
  match — no free text, no transmission, purely local and decorative.
- Local profile stats, an editable local display name, six badges, and
  a capped match-history list.
- A restrained, deterministic victory confetti burst on High visual
  quality (skipped for draws and when reduced motion is on).
- Resume: an in-progress match survives an app restart and can be resumed
  (landing paused) or discarded from the home screen.
- Adaptive visual-quality tiers (Low/Standard/High) and a "delete all local
  data" control.

## Getting started

Requires the Flutter SDK (this project targets the `^3.13.0` Dart SDK
constraint in `pubspec.yaml`) and, for Android builds, the Android SDK/NDK
matching the versions in **Android configuration** below.

```bash
flutter pub get
flutter gen-l10n        # regenerates lib/core/l10n/gen/ from lib/core/l10n/arb/*.arb
flutter analyze
flutter test
flutter run              # debug build on a connected device/emulator
```

Localization files under `lib/core/l10n/gen/` are committed (generated code
isn't produced by `flutter test` automatically), so re-run `flutter gen-l10n`
after editing anything under `lib/core/l10n/arb/` and commit the result.

### Release builds

```bash
flutter build apk --release          # universal debug-signed APK, for QA sideloading
flutter build appbundle --release    # Android App Bundle, Play's preferred format
```

The release `buildTypes` block in `android/app/build.gradle.kts` currently
signs release builds with the debug key (`signingConfig =
signingConfigs.getByName("debug")`), matching the Flutter template default —
replace this with a real upload keystore before any Play Store submission;
see [Android app signing](https://developer.android.com/studio/publish/app-signing).

> **Note on this repository's build history:** the sessions that developed
> this app ran in a sandboxed environment with an egress allowlist that did
> not include `dl.google.com`, so an Android SDK could not be installed
> there and `flutter build apk/appbundle` was never actually executed in
> that environment. Everything Android-build-independent — `flutter
> analyze`, the full unit/widget test suite, and the AndroidManifest/Gradle
> configuration itself — was verified there. **`.github/workflows/ci.yml`
> builds a real release APK/AAB and a debug APK on every push**, on
> GitHub's own hosted runners (which have a normal Android SDK
> preinstalled) — open the workflow run under the repo's **Actions** tab
> and download the `twelve-beads-apk` / `twelve-beads-appbundle` artifacts
> from its summary page to get an installable APK without needing a local
> Android SDK at all.

## Android configuration

| Setting | Value | Source |
|---|---|---|
| `applicationId` / `namespace` | `com.twelvebeads.twelve_beads` | `android/app/build.gradle.kts` |
| `compileSdk` | Flutter's current default (36 at last check) | `flutter.compileSdkVersion` |
| `targetSdk` | Flutter's current default (36 at last check) | `flutter.targetSdkVersion` |
| `minSdk` | Flutter's current default (24 at last check) | `flutter.minSdkVersion` |
| Permissions (release build) | **none** | `android/app/src/main/AndroidManifest.xml` |

The release manifest (`android/app/src/main/AndroidManifest.xml`) declares
no `<uses-permission>` at all — no `INTERNET`, no anything else — matching
the "no network permission" requirement. The `debug`/`profile` source sets
each add `android.permission.INTERNET`, but that's standard Flutter
tooling (needed for hot reload/DevTools) and is not part of a release build.

`compileSdk`/`targetSdk`/`minSdk` are read from the installed Flutter SDK's
own defaults rather than hardcoded, so they track "the current stable
Flutter/Android Gradle toolchain" automatically; the values above reflect
what that resolved to as of this app's Flutter SDK version — re-check
`flutter --version` / the Flutter Gradle plugin if updating the toolchain.

## Architecture

Feature-first layout with a strict `presentation → application → domain`
layering (`lib/game/` is plain Dart with zero Flutter imports):

```
lib/
  game/
    board/      # BoardGraph — validated 5x5 Alquerque adjacency, no rendering
    engine/     # GameState, GameAction, rules_engine.dart (pure functions),
                # MoveEvent — the single source of legal-move truth for both
                # human input and the AI
    ai/         # evaluation/search/machine_player — pure Dart, no Flutter
  core/
    l10n/ settings/ profile/ history/ theme/ routing/
  features/
    home/ game/ profile/ settings/ rules/
      application/   # Riverpod controllers (MatchController,
                      # MachineController, MovePresentationController, ...)
      presentation/   # screens/widgets — never talk to repositories directly
```

Persistence is versioned `SharedPreferences` + JSON (one repository per
entity: settings, profile, match history, the single resumable saved game),
matching the pattern in `03-architecture-and-data.md` but without a
SQL/Drift dependency — see the Phase 6 note in `docs/spec/DECISIONS.md` for
why.

## Testing

```bash
flutter test
```

The suite spans pure-Dart engine/AI unit tests, Riverpod controller tests
(including `fake_async` clock/timer tests and cross-provider hand-off
tests), and full widget tests for every screen and the human↔machine move
flow, per the test pyramid in `08-testing-and-delivery-plan.md`.

## CI

`.github/workflows/ci.yml` runs on every push, every pull request, and can
also be triggered manually from the Actions tab
(`workflow_dispatch`): `flutter analyze`, a `dart format` check, a check
that `lib/core/l10n/gen/` is up to date with
`lib/core/l10n/arb/*.arb`, the full test suite, and (in a second job) a
release APK, a release App Bundle, and a debug APK build, each uploaded as
a downloadable workflow artifact — the release build only runs on GitHub's
hosted runners, not in the sandboxed environment this app was originally
developed in (see **Release builds** above).

## Documentation

- `00-master-claude-code-prompt.md` through `08-testing-and-delivery-plan.md`
  — the numbered build brief this app was implemented against.
- `docs/spec/board-graph.md` — the validated board graph derivation.
- `docs/spec/DECISIONS.md` — every open rules/product/engineering question,
  its resolution, owner, and date; also records every deliberate scope
  simplification (e.g. badge thresholds, why High visual quality stays
  conservative, why the board doesn't mirror in RTL) rather than leaving
  them undocumented.

## Privacy

No accounts, no ads, no analytics, no internet permission in the release
build. All data (settings, profile stats/badges, match history, an
in-progress match) is stored locally via `SharedPreferences` and can be
erased in one action from Settings → "Delete local data".
