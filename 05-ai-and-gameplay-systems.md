# AI and Gameplay Systems

## AI principles

AI receives only the same immutable `GameState` and `legalActions` output as a player. It never operates the UI and cannot bypass the engine. Run search off the animation path; provide cancellable thinking when a game is paused/restarted. On accepted action, the application emits domain `MoveEvent`s into the shared opponent-move presentation timeline; AI never chooses animation timing or visual geometry.

## Difficulty contract

| Level | Behaviour |
|---|---|
| Easy | weighted/random legal choice; always takes obvious captures if rules require them |
| Medium | shallow minimax/negamax with alpha-beta; captures, material and mobility |
| Difficult | deeper iterative deepening, move ordering, transposition cache with time budget |

Use deterministic seeded randomness for reproducible tests, while using a fresh local seed for normal matches. Add a small human-like display delay range that does not pretend to be strength, is bounded/cancellable and skippable in accessibility settings. Show a localized thinking indicator during this state; obey the clock policy.

## Evaluation and safeguards

Evaluate terminal outcome first, then material, capture opportunities, mobility, threatened pieces, positional control and repetition risk. Bound node/time budgets per device quality; retain a legal fallback move. Test AI only returns legal actions, recognizes forced wins/captures, remains responsive under cancellation, and does not block the UI isolate.

## Quick chat and feedback

Quick-chat is a local overlay tied to the active side, rate-limited, localized, and dismisses automatically. Audio cues: selection, move, capture, warning, end. Haptics: subtle selection/capture/end patterns. All are independently toggleable and must never be required to understand game state.
