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
