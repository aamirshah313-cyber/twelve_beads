# Testing and Phased Delivery

## Test pyramid

- **Unit:** graph, rules engine, jumps/captures, terminal states, action/event replay, timers, AI legality/evaluation, badges, serializers/migrations and presentation-timeline sequencing/cancellation.
- **Widget:** board semantics/selection, human and machine opponent source/destination/path states, capture and chained-capture steps, last-move marker, thinking/turn cues, responsive rails, dialogs, localization/RTL, settings, profiles/history.
- **Integration:** complete local and machine games; pause/restart/resign/background during opponent playback; timeout, persistence and replay; language switch, data deletion; sound/haptic preference behavior; reduced-motion and Low-tier move comprehensibility.
- **Manual:** Android device matrix, TalkBack, large text, color vision, no-network launch, performance/thermal checks.

## Delivery phases

| Phase | Scope | Exit condition |
|---|---|---|
| 0 — Discovery | Inspect image, approve ruleset, encode graph and tests | Graph/relation tests and board-graph document approved |
| 1 — Foundation | Flutter shell, tokens, localization scaffold, storage, navigation | Offline launch and EN/UR navigation pass |
| 2 — Core match | Engine, procedural board, local two-player, result flow | Legal/capture/terminal tests + playable match pass |
| 3 — Intelligence/time | AI three levels, clocks, pause/resume/save | AI legality, clock lifecycle, resume tests pass |
| 4 — Progression | profiles, history, stats, badges, quick chat | Finalization is atomic and rendered correctly |
| 5 — Polish | audio/haptics, quality tiers, accessibility, responsive refinement | accessibility and low-end performance checks pass |
| 6 — Release | Android matrix, signing, release AAB/APK validation | Release smoke tests and manifest audit pass |

## Definition of done

Each phase includes source formatting, static analysis, test output, updated documentation, and a short changelog. No phase may replace image-derived board data with visual approximations. Record unresolved product decisions in `docs/spec/DECISIONS.md` with owner/date/status.

## Handoff checklist

- Setup, build and test commands documented.
- Ruleset and board graph versioned and explained.
- All user-visible copy translated and RTL reviewed.
- Offline, privacy, and deletion behavior verified.
- Release artifact/version/ABI coverage and device test notes recorded.
- Manual QA confirms every human-opponent and machine-opponent move, capture and chained capture remains visually traceable, synchronized and replayable on Low/Standard/High and reduced-motion configurations.
