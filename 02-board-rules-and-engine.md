# Board, Rules, and Game Engine

## Rule-source policy

Twelve Beads has regional variations. The product owner must approve these decisions after source-image inspection: initial placement, movement phase, capture jump geometry, mandatory capture, multi-capture turns, repetition/draw handling, win threshold, stalemate, and undo rules. Define a `Ruleset` with defaults plus named variants; display the active variant in Rules and match history.

## Board representation

Use stable node identifiers, an undirected adjacency list, and coordinates only for rendering. Model:

```dart
class BoardGraph { Map<NodeId, Offset> positions; Map<NodeId, Set<NodeId>> edges; }
class GameState { BoardGraph graph; Map<NodeId, Piece> pieces; Player turn; Phase phase; ... }
```

Never treat nearby visual nodes as connected. A simple move must follow one graph edge. A jump capture needs a valid source → jumped-node → landing-node relation derived from explicitly declared board lines; represent this as `Jump(source, over, landing)`, not an unsafe geometric midpoint guess.

## Engine contract

- Pure Dart domain package: no Flutter imports, no persistence, no timers.
- `legalActions(state)`, `apply(action)`, `result(state)`, `serialize(state)`, and invariant checks.
- Action types: select-free `Move`, `Capture`, optional chained-capture continuation, `Resign`, `Timeout`.
- UI may highlight candidates, but calls the engine to confirm each action.
- Use an action log plus deterministic initial seed for replay/history/debugging. Emit versioned, immutable `MoveEvent` data for presentation/replay: match/action/sequence IDs, actor, action type, source, destination, ordered jumped/captured nodes, continuation index, resulting turn and ruleset version. This is derived from accepted engine actions, never from animation coordinates.

## Required invariant tests

- Pieces only occupy declared nodes; no overlap; counts remain conserved except capture removal.
- Legal destinations use graph edges/jump table only.
- Capture policy and chained-capture rule are enforced consistently.
- Turn changes exactly when rules permit; terminal states admit no play action.
- Replay from seed/actions reproduces final state.
- Every image-derived edge and jump has positive/negative test cases.
- Event data faithfully represents moves, captures and each chained-capture step; replay from event/action data reaches the same final state.

## Interaction model

Tap a movable piece, show legal targets, then tap a target. Second tap can change selection; inaccessible taps announce why. In a forced-capture state, emphasize required capture choices. Cancel/back clears selection without changing state.
