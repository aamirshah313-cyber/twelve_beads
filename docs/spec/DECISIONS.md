# Decisions Record — Twelve Beads / بارہ گوٹی

Tracks product/rules decisions per `02-board-rules-and-engine.md` and
`08-testing-and-delivery-plan.md`. All rules questions (D-003 through D-009)
are now resolved via documented defaults so Phase 2 could proceed; none are
currently open, but every default below is easy to override on request.

## Resolved

| ID | Topic | Decision | Owner | Date | Status |
|---|---|---|---|---|---|
| D-001 | Board geometry | Reference image encodes a 5×5, 25-node grid with full orthogonal connectivity plus both diagonals in all 16 unit cells (classic Alquerque connectivity). See `docs/spec/board-graph.md`. | aamirshah313@gmail.com | 2026-08-19 | Resolved |
| D-002 | Starting piece count | The reference image shows 10 pieces/side (2 full rows, empty middle row); product owner confirmed this is illustrative only and the board geometry is authoritative, not the pictured piece count. Actual starting layout uses the classic 12-a-side arrangement: each side occupies its 2 home rows plus the 2 middle-row nodes nearest its side (`r2c0`,`r2c1` for the top side; `r2c3`,`r2c4` for the bottom side), leaving only the true center node `r2c2` empty. Implemented as `StandardStartingLayout` in `lib/game/board/board_graph.dart`. | aamirshah313@gmail.com | 2026-08-19 | Resolved |
| D-003 | Movement phase | Resolved by default: no separate drop/placement phase — all 24 seeded pieces move from their starting nodes from turn one, matching classic Alquerque. Implemented structurally (no "unplaced piece" concept exists in `GameState`). | Claude (default, per Ruleset.classicAlquerque) | 2026-08-19 | Resolved — default, override welcome |
| D-004 | Simple-move direction | Resolved by default: movement is omnidirectional for both simple moves and jumps — no forward-only restriction, no promotion/king concept, matching classic Alquerque. Structural: `legalActions` always uses full `BoardGraph` adjacency in every direction. | Claude (default) | 2026-08-19 | Resolved — default, override welcome |
| D-005 | Mandatory capture | Resolved by default: `Ruleset.classicAlquerque.mandatoryCapture = true` — a player holding any available capture anywhere on the board must play a capture, not a simple move. Maximum-capture-line selection is **not** required (any legal capture satisfies the obligation, unlike International Draughts) — this sub-question is a deliberate simplification, flagged for confirmation. | Claude (default) | 2026-08-19 | Resolved — default, override welcome |
| D-006 | Multi-capture turns | Resolved by default: `Ruleset.classicAlquerque.chainCaptureMandatory = true` — continuing a capture chain is mandatory once started, and turn control only passes once no further capture is available from the landing node. | Claude (default) | 2026-08-19 | Resolved — default, override welcome |
| D-007 | Repetition / draw handling | Resolved as an engineering safeguard rather than a traditional rule: `Ruleset.classicAlquerque.noCaptureMoveLimitForDraw = 40` plies without a capture ends the match in a draw, guaranteeing termination. No repetition-of-position detection is implemented in Phase 2. | Claude (default) | 2026-08-19 | Resolved — default, override welcome |
| D-008 | Win threshold | Resolved by default: `Ruleset.classicAlquerque.stalemateIsLossForPlayerToMove = true` — a side wins either by eliminating all opposing pieces, or by leaving the opponent with zero legal actions on their turn (stalemate counts as a loss for the player to move, not a draw). | Claude (default) | 2026-08-19 | Resolved — default, override welcome |
| D-009 | Undo policy | Resolved as a product default (UI-layer, enforced in Phase 3): undo is available in local two-player mode only, limited to the single most recently completed action, and disabled entirely while a capture chain is in progress (the whole chain-so-far must complete before any undo is offered). Not offered in vs.-Machine mode after the machine has moved. The Phase 2 engine itself has no undo concept — this is achieved by replaying the action log minus its last entry. | Claude (default) | 2026-08-19 | Resolved — default, override welcome |
| D-010 | "Current streak" semantics | Resolved as a product default (Phase 6): `ProfileStats.currentStreak` counts only consecutive **wins** — it increments on a win and resets to 0 on any loss or draw. A separate signed win/loss streak was considered and rejected as more confusing for the plain "Current streak" stat label without further UI decoration. | Claude (default) | 2026-08-19 | Resolved — default, override welcome |

All of D-003 through D-009 are implemented as the single named `Ruleset.classicAlquerque` in `lib/game/engine/ruleset.dart` — a default chosen because this board's confirmed 12-a-side, empty-center layout (D-002) already places it in the traditional Alquerque family, not a claim that this exact rule combination has been verified against a specific regional source. Every one of these remains easy to override: add a new named `Ruleset` and switch `GameState.initial(ruleset: ...)` — no engine changes required. Flag any of these to Claude at any time to adjust or replace with a different named variant.

## Non-blocking notes

- `ReferenceStartingLayout` was renamed to `StandardStartingLayout` once D-002
  was resolved, since it is now a confirmed game rule rather than a raw
  observation of the reference image.
- The reference board image itself was supplied inline in this session (not
  committed to the repository), per the master prompt's instruction not to
  ship, rasterize, or use the image as a runtime asset — the board is
  recreated procedurally from the validated graph.
- Known accessibility gap from Phase 3: multiple same-side pieces with no
  other distinguishing state currently share an identical semantic label
  (e.g. every unselected top bead reads as "Alice's bead"), so a TalkBack
  user can tell a piece's owner but not which specific junction they're on
  by label text alone (swipe order is still correct/consistent). Deferred to
  Phase 7 (accessibility polish), where each node's label can include its
  position (the `describeNode`/`nodePosition` helper added in Phase 4 for
  move announcements can be reused there).
- Phase 4 scope notes:
  - Sound cues are wired end-to-end (`SoundPort`, called at the right
    presentation-timeline moments, gated by `settings.soundOn`) but
    currently a documented no-op (`NoopSoundPort`) — no licensed audio
    assets are bundled yet. Haptics are real (`HapticFeedback` via
    `HapticsPort`). Swap in a real `SoundPort` once assets are sourced.
  - The High visual-quality tier currently uses the same timing/trail
    treatment as Standard (no additional particles/shaders) — the spec
    only allows richer High-tier effects "after profiling," which belongs
    in Phase 7 alongside the rest of the performance work.
  - The move-presentation timeline is driven by plain `Timer`s in the
    `MovePresentationController` Riverpod notifier, not a widget-owned
    `Ticker`/`AnimationController`. This keeps timing logic independent of
    any widget's vsync and easy to unit-test with `fake_async`, but it
    means `tester.pumpAndSettle()` alone does not wait for it in widget
    tests (a bare `Timer` isn't scheduler-tracked the way a Ticker is) —
    tests use an explicit `tester.pump(duration)` after interactions that
    trigger a move instead. `SystemGameClock` reads `package:clock`'s
    ambient clock (not raw `DateTime.now()`) specifically so this stays
    correct inside `flutter_test`'s `fake_async` zone.
  - Node numbering starts at row 0 / column 0 internally (`r{row}c{col}`,
    per `board_graph.dart`); screen-reader announcements add 1 for the
    1-indexed "row X, column Y" phrasing humans expect.
- Phase 5 scope notes:
  - The machine opponent is a pure-Dart negamax/alpha-beta search
    (`lib/game/ai/`) that only ever consults `legalActions`/`apply` from
    the shared rules engine — it has no privileged view of the board and
    cannot bypass mandatory capture, chain-capture continuation, or any
    other rule a human player is bound by. Easy picks uniformly at random
    among legal actions (weighted toward captures only in the sense that a
    forced-capture position has no non-capture actions to pick from).
    Medium is a fixed-depth-3 search. Difficult is iterative deepening
    with a ~1.2s wall-clock time budget, alpha-beta pruning, move
    ordering, and a transposition table.
  - Medium/Difficult search runs via `Isolate.run` so a non-trivial search
    never blocks the UI isolate; Easy resolves synchronously since it's
    cheap. The dispatch point (`machineComputeProvider`) is a Riverpod
    provider so tests can override it with a fast synchronous fake and
    avoid paying real isolate spawn/timing costs — the search algorithm
    itself is covered separately and directly in `test/game/ai`.
  - `MachineController` adds an artificial minimum "thinking" delay
    (~450-700ms, jittered; ~60ms under reduced motion) before applying a
    machine move, purely so the opponent doesn't feel instant/robotic on
    Easy — this is deliberately separate from actual search time. Any
    match-state change (human move, pause, resume, restart, resign) bumps
    a monotonic generation counter; a stale delay or search result that
    resolves after the generation has moved on is discarded rather than
    applied, which avoids needing true isolate preemption.
  - The machine's chosen action is applied through
    `MatchController.applyExternalAction`, which re-validates legality via
    `isLegal` before applying — the same guard a human's tap goes through
    — and feeds the exact same `MovePresentationController` timeline used
    for human moves, so opponent-move visualization (Phase 4) works
    identically regardless of who moved.
  - The machine's display name (`machineOpponentName`, localized) is set
    as `MatchConfig.playerTwoName` at match-setup time rather than being
    special-cased anywhere in the match/board widgets — `nameForSide()`
    and everything built on it (turn banner, player rail, dialogs,
    announcements) needed no changes to support vs-Machine matches.
- Phase 6 scope notes:
  - Persistence uses versioned `SharedPreferences` + JSON (matching the
    pattern already established for `Settings`/`Profile` in Phase 1),
    not Drift/SQLite as suggested as an example in
    03-architecture-and-data.md. Given this app's modest local data
    volumes (one profile, a capped match-history list, a single
    resumable game) and no cross-entity querying needs, a heavier
    embedded-SQL dependency wasn't judged worth its build-complexity
    cost (native bindings, codegen). Each repository still follows the
    spec's required shape: a stable storage key with a `.v1` schema
    suffix, corruption recovery (malformed data is discarded and
    recovered to a safe default — for match history, per-entry, not the
    whole list), and a `deleteAll()`/"delete local data" path.
  - All aggregate stats, badges and match history are tracked from
    `MatchConfig.playerOneSide`'s perspective only — this app has a
    single local profile (Phase 1), so "the profile's own side" is
    always Player 1, whether the match is two-player pass-and-play or
    vs-Machine. There is no per-profile-selection or multi-profile
    support in this phase.
  - `MatchRecord` (match history) stores only summary fields (outcome,
    win reason, move count, own captures, mode/difficulty, timestamps)
    — not the full action log. Full deterministic replay-from-history is
    out of scope for Phase 6; the engine's `replay`/`replayWithEvents`
    (Phase 2) remain the mechanism actually used for undo and for
    autosave/resume (see next point), so nothing about the "action log
    is the one authoritative replay source" principle is violated by
    history being summary-only.
  - The "SavedGame" resumable-match feature persists exactly one slot
    (the spec's schema table lists `SavedGame` as a single row, not a
    list) — starting a new match or restarting silently discards any
    previous in-progress one. A resumed match always lands **paused**
    (never auto-resumes the clock or, for vs-Machine, the opponent) so
    the player must explicitly continue. Autosave writes happen after
    every move/undo and on pause, not on every clock tick, to keep
    persistence I/O infrequent; a match is never saved once finished
    (`_finalizeMatch` clears any saved snapshot first) and never saved
    before its first move (nothing to resume).
  - Badge thresholds (5 captures for Capture Specialist, ≤12 moves for
    Fast Finish, ≥60 moves for Patient Player) are sensible chosen
    defaults, like the existing 40-turn no-capture draw limit — not
    derived from any specified source. Easy to retune in
    `lib/core/profile/badges.dart` on request.
  - A real cross-cutting bug was caught by testing here: `MatchController
    .build()` initially tried to synchronously clear the one-shot
    `pendingResumeSnapshotProvider` hand-off during its own `build()`,
    which Riverpod explicitly disallows ("providers are not allowed to
    modify other providers during their initialization"). Fixed the same
    way Phase 5's `MachineController` handles its analogous initial-turn
    check: defer the cross-provider write by one `Future.microtask()`.
- Phase 7 scope notes (polish and accessibility):
  - Closed the Phase 3 accessibility gap: board node semantic labels now
    include position (`describeNode`/`nodePosition`, moved to a shared
    `node_description.dart` so both the board's own hit-target labels
    and the move-announcement code use the exact same phrasing) — a
    TalkBack user can now tell same-owner pieces apart by label alone,
    not just swipe order.
  - Closed the Phase 4 "High visual-quality tier == Standard" gap with a
    single, deliberately restrained addition (a soft blurred glow behind
    the captured-piece marker during capture playback), gated on
    `VisualQuality.high` and skipped under reduced motion. No general
    particle system was built: this project has no profiling
    infrastructure, and 04-ui-ux-and-visual-system.md explicitly gates
    richer High-tier effects on "after profiling" — so High stays
    intentionally conservative rather than adding unverified-cost
    effects. Low vs. Standard were already differentiated in Phase 4
    (crisp/near-instant timing, no trail); that didn't change here.
  - Fixed a real defect: `AppSettings.highContrast` boosted the Material
    3 `ColorScheme`'s contrast level (background/edges/rings, which read
    `colorScheme` directly) but had **zero effect on the beads
    themselves**, since they used hardcoded thematic colors
    (`topBeadColor`/`bottomBeadColor`) applied directly rather than
    through the color scheme. Added `effectiveBeadColor()`
    (`board_painter.dart`): under high contrast, the same thematic hue
    is saturation-boosted and pushed away from mid-lightness (darker on
    a light theme, lighter on a dark one) rather than switched to a
    theme accent color — this keeps the bead hue distinct from the
    board's own functional overlay colors (selection rings, forced-
    capture rings, last-move markers all already use
    primary/secondary/tertiary/error), so a high-contrast bead can never
    be confused with one of those cues.
  - RTL: the surrounding UI (text, `Row`/`Column` layout, `Directionality`)
    already mirrors correctly via Flutter's built-in RTL support — no
    code changes were needed there beyond one real bug: the home
    screen's menu buttons used physical `Alignment.centerLeft` for their
    icon+label content, which stayed left-aligned even in Urdu. Fixed to
    `AlignmentDirectional.centerStart`. The board grid itself
    (`board_layout.dart`) is a **deliberate exception**: it does not
    mirror in RTL. A board's spatial layout is functional, not textual —
    "top"/"bottom" already encode the two sides per the game's own
    rules, and two people sharing one device in local pass-and-play
    expect the physical board geometry to stay fixed regardless of the
    active display language, the same way a chess or checkers board
    doesn't rotate for an RTL locale.
  - Performance: `BoardPainter.shouldRepaint` previously always returned
    `true` (an unconditional full repaint on every rebuild, including
    every 60fps-ish tick of the presentation timeline's travel
    animation). Replaced with a real diff across every field that
    affects paint output (pieces, selection, legal/forced-capture sets,
    last-move markers, the full presentation overlay, color scheme,
    high-contrast/high-quality-effects flags) — `layout`/`graph` are
    deliberately excluded since a board resize already repaints
    independently of this delegate check (confirmed against
    `RenderCustomPaint`'s own doc comment), and `graph` never changes
    mid-match. Also wrapped the board's `CustomPaint` in a
    `RepaintBoundary` so its (now-cheaper) repaints don't force
    surrounding widgets (turn banner, player rails) to repaint too.
  - Also fixed, while auditing the player rail: a long localized player
    name at a large text-scale factor could overflow the `Row` (no
    `Flexible`/ellipsis previously) — wrapped the name in
    `Flexible(overflow: TextOverflow.ellipsis)`.
- Phase 8 scope notes (release validation):
  - **Known limitation, not silently skipped**: the sandbox this app was
    developed in has an outbound-network allowlist that does not include
    `dl.google.com` (confirmed via the sandbox's own proxy status
    endpoint reporting a policy-denied `403` on that host), and no
    Android SDK was pre-installed. `flutter build apk --release` /
    `flutter build appbundle --release` were therefore never actually
    executed there — everything Android-SDK-independent was: `flutter
    analyze`, the full test suite, and a manual audit of
    `AndroidManifest.xml`/`build.gradle.kts`. Running the two build
    commands on a machine with a normal Android SDK install is the one
    remaining verification step; see the README's "Release builds" note.
  - Manifest audit: the release manifest
    (`android/app/src/main/AndroidManifest.xml`) declares zero
    `<uses-permission>` entries — confirmed by reading the file, not
    inferred. `debug`/`profile` source sets each add `INTERNET`, which is
    standard Flutter tooling (hot reload/DevTools) and doesn't reach a
    release build. Fixed `android:label` from the raw package-style
    string `"twelve_beads"` to the actual display name `"Twelve Beads"`.
  - `compileSdk`/`targetSdk`/`minSdk` are left reading the installed
    Flutter SDK's own defaults (`flutter.compileSdkVersion` etc. in
    `build.gradle.kts`) rather than hardcoded, so the toolchain choice
    stays current automatically, per "use the current stable Flutter/
    Android Gradle toolchain." Recorded what that resolved to (36/36/24)
    in the README, per "record exact decisions in README."
  - The launcher icon was still the default Flutter template logo.
    Replaced it with a small procedurally-generated icon (Python/Pillow,
    not part of the app's own build) using the exact same bead colors
    and shape-differentiation (solid vs. ring-punched) as the in-game
    pieces, at all five legacy mipmap densities — a placeholder
    consistent with the app's own visual language, not final brand art.
  - Match finalization (`MatchController._finalizeMatch`) writes to
    three separate `SharedPreferences`-backed repositories (match
    history, profile stats, saved-game clear) sequentially, not inside
    one atomic transaction — `SharedPreferences` has no cross-key
    transaction primitive to wrap them in. A crash in the narrow window
    between these writes could leave one of the three not yet updated,
    but never corrupt: each repository's own stored value is always a
    complete, independently-valid JSON document (never a partial write),
    and every repository already discards/recovers from malformed data
    on load. Accepted as a reasonable trade-off for a local casual game
    with no competitive stakes in its history, per
    07-android-quality-security-and-release.md's own framing ("do not
    trust client-side history as competitive proof").
  - **Gap found during the final cross-check against every numbered spec
    file, not during any earlier phase**: local quick chat (00-master-
    claude-code-prompt.md, 01-product-requirements.md,
    05-ai-and-gameplay-systems.md "Quick chat and feedback",
    06-localization-social-and-settings.md, and the Phase 4/"Progression"
    row of 08-testing-and-delivery-plan.md all require it) had never
    actually been implemented in any prior phase. Added it here rather
    than treating the project as done with a documented requirement
    silently missing: a fixed preset of six localized phrases (no free
    text, nothing ever transmitted), shown as a transient overlay that
    auto-dismisses after 3 seconds. Rate limiting is achieved by
    construction rather than a separate cooldown clock: a new phrase
    can't be sent while one is still showing, which already spaces sends
    at least `displayDuration` apart and keeps the send-button's enabled
    state trivially reactive (no polling needed to know when the "cooldown"
    has elapsed). "Tied to the active side" is interpreted as: in local
    two-player pass-and-play, whichever side's turn it currently is; in
    vs-Machine mode, always the human (`playerOneSide`) regardless of
    whose turn it is, since a human tapping the button should never
    appear to "speak as" the machine opponent.
  - **Second gap found the same way**: 01-product-requirements.md's
    "Timers:" line specifies an *optional per-move* timer (15/30/45/60/
    custom sec) and a *warning threshold*, on top of the total-time
    timer already built in Phase 3 — neither existed. Added both,
    extending (not replacing) `MatchController`'s existing arm/tick/
    freeze timer machinery rather than introducing a parallel one:
    - The per-move budget resets only on a genuine turn change, not
      mid capture-chain (a forced chain is still "one move" for this
      purpose) — determined by comparing `GameState.turn` before/after
      applying an action, not by counting individual jumps.
    - `undo()` resets the per-move budget to full for the side whose
      move was undone, rather than trying to reconstruct exactly how
      much they'd already spent — there's no historical per-action
      timing record to reconstruct it from, and "fresh attempt" is the
      more defensible interpretation anyway.
    - The warning threshold (last 10 seconds of whichever clock —
      total or per-move — is closer to expiry) fires the haptic/sound
      "warning" cue (added to `HapticsPort`/`SoundPort`) exactly once
      per arm via a `_warnedForCurrentArm` flag reset alongside
      `_armClock`, not on every tick while under threshold. The exact
      same `Duration` constant (`timerWarningThreshold`, exported from
      `match_controller.dart`) drives the player rail's countdown text
      turning red, so the visual and audible/haptic cues can never
      drift out of sync with each other.
    - Setup-screen "custom" values use a sentinel dropdown entry
      (`_customTimerSentinel = -1`, never a real timer value since both
      minutes and seconds are always >= 0) that reveals a numeric
      `TextField`, rather than a separate widget/dialog — kept the
      pre-game form's existing `DropdownMenu`-per-setting layout
      consistent rather than introducing a new interaction pattern for
      just these two fields.

  - **Third gap found the same way**: 04-ui-ux-and-visual-system.md's
    "States and motion" line ("victory confetti only on capable tier")
    was unimplemented. Added `VictoryConfetti`, a self-contained,
    `IgnorePointer`d, one-shot (1.6s) `CustomPainter` burst shown only
    when `VisualQuality.high` *and* the match ended in a win (not a
    draw) *and* reduced motion is off — gated in `MatchScreen`'s
    existing match-finished `ref.listen`, alongside the pre-existing
    match-over-dialog trigger, and reset on restart/new match the same
    way `_dialogShown` already was. Deterministic seed (`Random(7)`),
    not truly random per play, since this is decoration rather than a
    game-state-derived cue — consistent with this project's general
    "restrained, not unverified-cost" approach to High-tier effects.
  - **Fourth gap found the same way**: 01-product-requirements.md's
    "Profiles: local display name/avatar selection" line was only
    half-built — `ProfileController.setDisplayName` existed and was
    fully wired to persistence, but nothing in the UI ever called it;
    the Profile screen only *displayed* `stats.displayName`, with no
    way to set it. Added an edit-pencil `IconButton` next to the name
    on `ProfileScreen`, opening a small `AlertDialog`
    (`_EditNameDialog`, a dedicated `StatefulWidget` so its
    `TextEditingController` is created/disposed on the dialog's own
    lifecycle rather than raced against the dialog's closing
    animation) with Cancel/Save; an empty/whitespace-only name is
    discarded rather than saved. Avatar *selection* (choosing among
    multiple icons/colors, beyond the existing initial-letter
    `CircleAvatar`) was left out: 01 states "One default profile is
    sufficient; support multiple local profiles if low-cost," and
    avatar picking is decoration with no gameplay or accessibility
    consequence, unlike the display name (which appears in quick chat,
    match history, and the turn banner) — a deliberate scope line, not
    an oversight.
  - **Fifth and sixth gaps, found doing a targeted pass against 05 and
    07 specifically** (rather than the earlier line-by-line pass across
    all nine documents): 05-ai-and-gameplay-systems.md's evaluation
    section calls for AI node/time budgets "bound ... per device
    quality," and separately 07's "Release validation" section opens
    with "`flutter analyze`, formatting, unit/widget/integration
    suites, and release build must pass in CI" — neither existed.
    - `Difficulty.difficult`'s iterative-deepening search always used
      the same fixed ~1.2s time budget regardless of the device. Since
      this app has no real device-capability probe, `VisualQuality`
      (already the user-facing proxy for "how much this
      device/session can spend," per 04) doubles as that signal:
      `difficultTimeBudgetFor()` in `machine_controller.dart` now
      gives `VisualQuality.low` a 500ms budget and leaves
      Standard/Auto/High at the existing 1.2s default. Plumbing this
      through required adding a `difficultTimeBudget` parameter to
      `MachineComputeFn` (the seam that already carries `seed` across
      the `Isolate.run` boundary for the same reason: a spawned
      isolate can't read `ref`/settings itself, so the value has to be
      resolved on the calling side and passed in as plain data).
    - Added `.github/workflows/ci.yml`: one job running
      `flutter pub get` → `flutter gen-l10n` + `git diff --exit-code`
      (catches committed `lib/core/l10n/gen/` drifting from the
      `.arb` sources) → `dart format --set-exit-if-changed .` →
      `flutter analyze` → `flutter test`, and a second job building
      the release APK and App Bundle (no signing secrets needed, since
      release currently signs with the debug key — see the README's
      "Release builds" note). This workflow could not actually be
      exercised inside this project's own development sandbox, whose
      network policy blocks `dl.google.com` (see the Phase 8 note
      above) — GitHub Actions' hosted runners have normal internet
      access and a preinstalled Android SDK, so it should run for
      real the first time this branch is pushed or a PR is opened
      against it, which is the first opportunity to confirm it
      actually passes end-to-end.
  - **Seventh gap, found doing a targeted pass against 06 and 08 —
    a real functional bug, not just a missing feature.** 06's "Move-
    feedback preferences" section requires sound and haptics to be
    "independently configurable"; `AppSettings.hapticsOn` and
    `.soundOn` existed, persisted correctly, and drove the Settings
    screen's own toggle switches — but nothing else in the codebase
    ever *read* either value. Every haptic call
    (`_haptics.move()`/`.capture()` in
    `MovePresentationController._beginStep`, `hapticsPortProvider`
    `.matchEnd()`/`.warning()` in `MatchController`) fired
    unconditionally: turning "Haptics" off in Settings did nothing at
    all — the device kept vibrating on every move, capture, warning
    and match end. Gated all of them behind
    `ref.read(settingsControllerProvider).hapticsOn` /`.soundOn` at
    each call site (matching this codebase's existing preference for
    small inline checks over a decorator/wrapper abstraction — see
    e.g. the `visualQuality`/`reducedMotion` checks already inline in
    the same functions). While auditing every call site, also found
    `HapticsPort.selection()`/`SoundPort.selection()` were declared in
    the interface (per 05's "Haptics: subtle selection/capture/end
    patterns") but never actually called anywhere — `onNodeTapped` in
    `MatchController` now fires a selection cue when a tap results in
    a new (non-null) selection, gated the same way. `NoopSoundPort`
    remains the documented sound no-op from Phase 4 either way, so the
    `soundOn` gating has no audible effect yet, but is now correct and
    ready for when a real `SoundPort` is added.
  - **Eighth gap, found the same pass**: 06's opening paragraph
    requires "plural/select support" in the ARB files; the one
    genuinely pluralizable string in the app, `historyMoveCount`
    ("{count} moves" in match history), was a flat placeholder that
    would read "1 moves" for a one-move match. Switched both
    `app_en.arb` and `app_ur.arb` to ICU `plural` syntax
    (`one`/`other` categories) — every other placeholder-bearing
    string in the ARB files (turn banner, announcements, quick chat,
    etc.) interpolates a name/position/phrase, not a bare count, so
    none of them needed the same treatment.
  - **Ninth gap, found the same pass**: 08's unit-test-pyramid line
    calls for "serializers/migrations" coverage. `SavedGameSnapshot`
    is the only persisted entity that has actually undergone a schema
    bump (v1 → v2, when `perMoveRemaining` was added in the gap-fill
    documented earlier in this file) and had no test exercising that
    migration path specifically — only the current (v2) shape was
    ever round-tripped. `saved_game_test.dart` now includes an
    explicit test that feeds `SavedGameSnapshot.fromJson` a v1-shaped
    map (no `perMoveRemainingMs` key at all) and asserts it loads
    cleanly with `perMoveRemaining: null`, rather than only relying on
    `fromJson`'s nullable cast to make that case work by accident.
