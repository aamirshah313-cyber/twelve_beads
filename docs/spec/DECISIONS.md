# Decisions Record — Twelve Beads / بارہ گوٹی

Tracks product/rules decisions per `02-board-rules-and-engine.md` and
`08-testing-and-delivery-plan.md`. Every open item here blocks the Phase 2
pure rules engine (`Ruleset`) until resolved by the product owner.

## Resolved

| ID | Topic | Decision | Owner | Date | Status |
|---|---|---|---|---|---|
| D-001 | Board geometry | Reference image encodes a 5×5, 25-node grid with full orthogonal connectivity plus both diagonals in all 16 unit cells (classic Alquerque connectivity). See `docs/spec/board-graph.md`. | aamirshah313@gmail.com | 2026-08-19 | Resolved |
| D-002 | Starting piece count | The reference image shows 10 pieces/side (2 full rows, empty middle row); product owner confirmed this is illustrative only and the board geometry is authoritative, not the pictured piece count. Actual starting layout uses the classic 12-a-side arrangement: each side occupies its 2 home rows plus the 2 middle-row nodes nearest its side (`r2c0`,`r2c1` for the top side; `r2c3`,`r2c4` for the bottom side), leaving only the true center node `r2c2` empty. Implemented as `StandardStartingLayout` in `lib/game/board/board_graph.dart`. | aamirshah313@gmail.com | 2026-08-19 | Resolved |

## Open — require product-owner approval before Phase 2

| ID | Topic | Question | Status |
|---|---|---|---|
| D-003 | Movement phase | Is there a distinct "drop"/placement phase, or do all 24 seeded pieces move from their starting nodes only (no separate placement phase, matching classic Alquerque)? | Open |
| D-004 | Simple-move direction | Can a piece move backward (toward its own home side) as a simple (non-capturing) move, or only forward/sideways? Classic Alquerque allows movement along any declared edge in any direction for both simple moves and jumps. | Open |
| D-005 | Mandatory capture | If a capture is available, must the player take it (forced capture), and if multiple captures are available, must the maximum-capture or highest-value line be chosen? | Open |
| D-006 | Multi-capture turns | When a capture leads to another available capture from the landing node, is continuing the chain mandatory, and does turn control pass only once the chain ends? | Open |
| D-007 | Repetition / draw handling | Is there a repetition rule (e.g. threefold repetition, or a move-count-without-capture limit) that ends a game in a draw? | Open |
| D-008 | Win threshold | Does a side win purely by reducing the opponent to zero pieces, or also by leaving the opponent with no legal move (stalemate-as-loss vs. stalemate-as-draw)? | Open |
| D-009 | Undo policy | Is undo available at all in local two-player or vs.-machine modes, and if so, is it limited to the immediately preceding action, unlimited within a turn, or disabled once a capture chain has started? | Open |

## Non-blocking notes

- `ReferenceStartingLayout` was renamed to `StandardStartingLayout` once D-002
  was resolved, since it is now a confirmed game rule rather than a raw
  observation of the reference image.
- The reference board image itself was supplied inline in this session (not
  committed to the repository), per the master prompt's instruction not to
  ship, rasterize, or use the image as a runtime asset — the board is
  recreated procedurally from the validated graph.
