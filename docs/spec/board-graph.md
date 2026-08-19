# Board Graph — Twelve Beads / بارہ گوٹی

Derived by inspecting the supplied reference board image. This document, plus
`lib/game/board/board_graph.dart` and `test/game/board/board_graph_test.dart`,
is the authoritative record of board geometry per the source-board gate in
`README.md` and `00-master-claude-code-prompt.md`. Nothing here was inferred
from a generic grid template — every edge and jump relation below is backed
by a test in `board_graph_test.dart`.

## What the reference image shows

- A 5×5 grid of 25 junctions (nodes), arranged in 5 rows and 5 columns.
- Every orthogonally adjacent pair of nodes (horizontal and vertical
  neighbors) is connected by a drawn line.
- **Both diagonals are drawn in every one of the 16 unit cells** — not just
  the board's two long diagonals, and not an alternating/checkerboard subset.
  This is the classic full "Alquerque" connectivity pattern: the densest
  crossing of lines is visible at the center node, where the diagonals of all
  4 surrounding cells converge.
- Starting pieces in the image: 10 orange beads on the top two rows, 10 green
  beads on the bottom two rows, entire middle row empty. **This piece count
  is illustrative only** — see `docs/spec/DECISIONS.md` for the resolved
  starting-layout decision (12 beads/side, not 10).

## Node numbering

Nodes are named `r{row}c{col}`, with `row` and `col` each `0..4`, `row 0` =
top, `col 0` = left — matching the image's natural top-to-bottom,
left-to-right reading order. Node IDs are stable, explicit strings; they are
never computed from pixel coordinates at runtime.

```
   c0    c1    c2    c3    c4
r0 •-----•-----•-----•-----•
   |\   /|\   /|\   /|\   /|
   | \ / | \ / | \ / | \ / |
r1 •-----•-----•-----•-----•
   |/ \ | / \ | / \ | / \ |
   |\   /|\   /|\   /|\   /|
   | \ / | \ / | \ / | \ / |
r2 •-----•-----•-----•-----•
   |/ \ | / \ | / \ | / \ |
   |\   /|\   /|\   /|\   /|
   | \ / | \ / | \ / | \ / |
r3 •-----•-----•-----•-----•
   |/ \ | / \ | / \ | / \ |
   |\   /|\   /|\   /|\   /|
   | \ / | \ / | \ / | \ / |
r4 •-----•-----•-----•-----•
```

(ASCII rendering is illustrative of connectivity density; see
`BoardGraph.standard()` for the exact declared edge set.)

## Adjacency summary

| Node class | Nodes | Degree | Connections |
|---|---|---|---|
| Corner | `r0c0`, `r0c4`, `r4c0`, `r4c4` | 3 | 2 orthogonal + 1 diagonal |
| Boundary, non-corner | 12 nodes (3 per side) | 5 | 3 orthogonal + 2 diagonal |
| Interior (inner 3×3) | 9 nodes | 8 | 4 orthogonal + 4 diagonal |

Totals: 25 nodes, 72 undirected edges (40 orthogonal + 32 diagonal), 96
directed `Jump(source, over, landing)` relations.

## Symmetry

The graph is 180°-rotationally symmetric about the center node `r2c2`
(rotating `(row, col)` to `(4-row, 4-col)` maps every edge onto another
declared edge, and every jump onto another declared jump). It is also
mirror-symmetric across both the horizontal and vertical center lines and
both main diagonals — full dihedral symmetry of the square, as expected for
a regular 5×5 grid with uniform per-cell diagonals. Verified by
`BoardGraph.standard() 180-degree rotational symmetry` tests.

## Jump (capture) relations

A `Jump(source, over, landing)` is only declared when `source→over` and
`over→landing` are both real graph edges, collinear along one of 8 axes
(4 orthogonal + 4 diagonal directions), landing on a node within the 5×5
grid. There is no midpoint-of-pixels heuristic: every jump is built by
walking the same declared edge set as simple moves, in `BoardGraph.standard()`.

- Corner nodes have exactly 3 outgoing jumps (all 3 of their edges reach a
  valid landing node, since corners sit at the grid extreme).
- Not every edge yields a jump — e.g. a boundary node one step from the edge
  of the grid in a given direction has no landing square in that direction.

## What this graph deliberately does not decide

Per `02-board-rules-and-engine.md`, board geometry and ruleset are separate
concerns. This graph says nothing about: mandatory capture, multi-capture
turns, movement-phase-only vs. drop-phase rules, repetition/draw handling,
win threshold, or stalemate. Those remain open in `docs/spec/DECISIONS.md`
until Phase 2 (pure rules engine).
