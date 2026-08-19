# Architecture and Local Data

## Layers

`presentation` (Flutter screens/widgets) → `application` (controllers/use cases) → `domain` (game engine, rules, AI contracts) ← `data` (local repositories, serializers, audio adapters). Domain must be platform-independent and thoroughly unit-tested.

Add a presentation-only `MovePresentationController`/timeline that consumes accepted domain `MoveEvent`s and serializes visual steps (thinking, source highlight, path, travel, capture removal, continuation, turn transition). It owns cancellation and input locking during playback; it must not mutate `GameState`, decide legality, or direct AI. Audio/haptic adapters subscribe to timeline events and honor settings.

Use a feature-first layout: `features/game`, `features/home`, `features/profile`, `features/settings`, `features/rules`; share design tokens and services. Choose one predictable state-management approach (Riverpod is suitable) and do not expose database objects directly to widgets.

## Suggested local schema

| Entity | Essential fields |
|---|---|
| Settings | language, sound, haptics, accessibility, visual quality, timer defaults, ruleset id |
| Profile | id, displayName, avatarId, createdAt, selected |
| Match | id, started/ended, mode, players, ruleset/version, result, duration, timer config, seed, action log/version, move-event timeline/version |
| AggregateStats | profileId, played, wins, losses, draws, captures, streaks, duration totals |
| BadgeProgress | profileId, badgeId, earnedAt/progress |
| SavedGame | state version, serialized legal state, active clock snapshot, updatedAt |

`MoveEvent` stores stable graph node IDs rather than pixels, plus actor, action type, source/destination, ordered captures, chain step and action sequence. Persist enough event/action context to replay a completed match deterministically; migrate or safely discard incompatible timeline versions.

Use a versioned local database appropriate for Flutter (for example Drift/SQLite) plus a simple preferences store for boot settings. Make migrations, corruption recovery, and a “delete local data” action. Store no sensitive data.

## Clock policy

Inject a monotonic clock. Persist running-clock snapshot on lifecycle changes. On resume, apply elapsed foreground/background time according to the documented timer policy (default: game clock pauses while app is inactive; disclose it). AI thinking must not consume a human clock unless configured.

## Badge examples

First Win; Five Matches; Capture Specialist; Three-Win Streak; Fast Finish; Patient Player. Badge conditions are deterministic and evaluated once per finalized match.
