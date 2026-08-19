# Master Claude Code Prompt

You are the principal Flutter engineer and mobile game UX lead. Build a production-quality, offline-first Android game named **Twelve Beads / بارہ گوٹی**. Read `README.md` and every numbered Markdown specification file in this directory in numeric order (or in `docs/spec` if this package is later relocated); treat them as the acceptance contract. Do not begin feature work until the source-board gate below is complete.

## Mandatory source-board gate

1. Locate and inspect `/mnt/data/images.jpg` (or ask for it if unavailable).
2. Identify every playable junction, every drawn connection, starting areas, symmetries, and any diagonals. Number junctions deterministically.
3. Create `lib/game/board/board_graph.dart` as explicit adjacency data; never calculate legal edges from pixel positions or assume an ordinary grid.
4. Add a documented node map to `docs/spec/board-graph.md`, including an annotated derived diagram (ASCII/SVG is fine) and its rule assumptions.
5. Write graph symmetry, edge, and move-generation tests. Stop and request clarification if the image is ambiguous; do not silently invent geometry.
6. Do not ship, rasterize, crop, or use the image as the live game board. Recreate the board procedurally from the validated graph.

## Delivery standards

- Flutter stable + Dart, Material 3; Android-first with phone and tablet-responsive layouts.
- Clean feature-first architecture with pure, deterministic rules engine separated from Flutter UI and AI.
- Fully playable offline: same-device two-player and one-player against on-device AI.
- English and Urdu with a visible language menu; Urdu is correctly RTL, uses a tested Urdu-capable bundled font, and mirrors layout only where appropriate.
- Premium tactile visual language: procedural 3D-like board and beads, motion, sound and haptics—but graceful quality tiers for low-end devices.
- No account, ads, remote analytics, network dependency, or internet permission in the base APK. “Chat” is local quick chat/emotes for the same-device experience; do not imply online multiplayer.
- Persist profiles, histories, badges, settings, and resumable game state locally. Avoid saving a game after it is already terminal.
- Use accessibility semantics, scalable text, contrast-safe states, reduced motion, haptic/sound controls, and screen-reader labels.

## Mandatory opponent-move visualization

Every opponent action must be understandable graphically, whether the opponent is the other local human or the machine. Never teleport a bead or silently replace board state. Treat the visual sequence as a first-class, cancellable presentation workflow driven by immutable engine action events—not by the AI or widget-side state guesses.

For each move, visibly identify its **source** and **destination** (ring/glow plus non-colour cue), draw a short-lived directional path/trail between them, animate the bead along that declared graph edge or jump, and keep a clear last-move marker after completion. Synchronize selection/move/capture/end sounds and optional haptics with the corresponding visual event. Respect the user’s sound, haptic, high-contrast and reduced-motion preferences.

For a capture, show the mover’s source → jumped piece → landing destination relationship, animate the movement, then remove the captured bead with a distinct restrained effect. For chained captures, animate and announce each jump in order, retaining context between steps; do not collapse a chain into a single teleport. The board must not accept conflicting input while an opponent sequence is being presented; pause/restart/resign/background transitions must safely cancel or complete the sequence without corrupting game state.

In machine mode, show a localized, accessible “Machine is thinking” state before the move, with a bounded/skippable human-like delay that does not affect AI strength or improperly consume a player clock. Then show the exact same move visualization used for a human opponent. Finish every action with an explicit, localized turn-transition cue.

Define a replay-ready, versioned move-event/timeline model that records source, destination, jumped node(s), action order, actor, timestamps/sequence numbers and ruleset/seed context. Replays must use this data and the engine action log; presentation effects must never be the authoritative rules record. Add an adaptive visual-quality policy: Low uses crisp highlights and short/instant transitions with no blur/particles; Standard uses lightweight trails; High may add restrained particles only after profiling. Reduced-motion provides immediate but still perceptible source/destination/capture/turn cues.

## Work method

Implement in the phases in `08-testing-and-delivery-plan.md`. At each phase: run formatter, analyzer, relevant unit/widget/integration tests, then report changed files, test results, and remaining decisions. Keep dependencies lean and maintained. Use immutable game state, seeded/replayable matches, and a single legal-move source of truth shared by player input and AI.

## Required completion checklist

- Accurate image-derived board graph is documented and tested.
- All documented game modes, timer modes, difficulty levels, profile/statistics/badges, quick chat, localization, settings, and offline flows work.
- Release APK/AAB builds succeed, validate broad SDK/ABI support, and have been manually smoke-tested on a small and large Android emulator/device configuration.
- `README.md` includes setup/build instructions, minimum supported Android version, known rule-variant assumptions, and privacy statement.
- Never claim rules correctness where the reference image or owner decision has not been verified.
- Opponent moves, including every machine and chained capture action, are graphically explainable, replayable and accessible on every quality tier.
