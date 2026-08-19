import '../board/board_graph.dart';
import 'game_action.dart';
import 'game_state.dart';
import 'move_event.dart';
import 'ruleset.dart';
import 'side.dart';

/// Thrown by [apply] when the given action is not legal for the given
/// state. Since the UI is required to only ever pass actions drawn from
/// [legalActions] (or a Resign/Timeout it originated), this indicates a
/// programming error, not an expected user-input rejection.
class IllegalActionException implements Exception {
  final String message;
  const IllegalActionException(this.message);

  @override
  String toString() => 'IllegalActionException: $message';
}

class ActionOutcome {
  final GameState state;
  final MoveEvent event;
  const ActionOutcome({required this.state, required this.event});
}

class MatchResult {
  final bool isOver;
  final Side? winner;
  final WinReason? winReason;
  final bool isDraw;

  const MatchResult({
    required this.isOver,
    this.winner,
    this.winReason,
    this.isDraw = false,
  });
}

/// Pure function: the board-and-ruleset-legal actions available in [state].
/// This is the single source of truth shared by human input validation and
/// the AI (a later phase) — neither may compute legality any other way.
List<GameAction> legalActions(GameState state) {
  if (state.phase != GamePhase.playing) return const [];

  if (state.mustContinueCaptureFrom != null) {
    return _capturesFromNode(
      state.graph,
      state.pieces,
      state.mustContinueCaptureFrom!,
      state.turn,
    );
  }

  final captures = _allCaptures(state.graph, state.pieces, state.turn);
  if (state.ruleset.mandatoryCapture && captures.isNotEmpty) {
    return captures;
  }

  final moves = _allMoves(state.graph, state.pieces, state.turn);
  return [...captures, ...moves];
}

/// Whether [action] is legal in [state]. Resign/Timeout are legal any time
/// the match is still in progress; Move/Capture must appear in
/// [legalActions].
bool isLegal(GameState state, GameAction action) {
  return switch (action) {
    ResignAction() || TimeoutAction() => state.phase == GamePhase.playing,
    MoveAction() || CaptureAction() => legalActions(state).contains(action),
  };
}

/// Pure function: applies [action] to [state], returning the resulting
/// state and the immutable [MoveEvent] record of what happened. Throws
/// [IllegalActionException] if [action] is not legal in [state].
ActionOutcome apply(
  GameState state,
  GameAction action, {
  required String matchId,
  required int actionSequence,
}) {
  if (!isLegal(state, action)) {
    throw IllegalActionException('$action is not legal in the current state');
  }

  return switch (action) {
    ResignAction(:final side) => _applyTermination(
      state,
      actor: side,
      actionType: 'resign',
      winner: side.opponent,
      winReason: WinReason.resignation,
      matchId: matchId,
      actionSequence: actionSequence,
    ),
    TimeoutAction(:final side) => _applyTermination(
      state,
      actor: side,
      actionType: 'timeout',
      winner: side.opponent,
      winReason: WinReason.timeout,
      matchId: matchId,
      actionSequence: actionSequence,
    ),
    MoveAction(:final from, :final to) => _applyMove(
      state,
      from: from,
      to: to,
      matchId: matchId,
      actionSequence: actionSequence,
    ),
    CaptureAction(:final from, :final over, :final to) => _applyCapture(
      state,
      from: from,
      over: over,
      to: to,
      matchId: matchId,
      actionSequence: actionSequence,
    ),
  };
}

/// Pure function: reads the terminal outcome, if any, already computed on
/// [state] by [apply].
MatchResult result(GameState state) => MatchResult(
  isOver: state.phase == GamePhase.finished,
  winner: state.winner,
  winReason: state.winReason,
  isDraw: state.isDraw,
);

/// Deterministically replays [actions] from a fresh initial state built from
/// [ruleset] and [firstTurn] ("seed"), returning the final [GameState].
/// Since Phase 2 has no in-engine randomness, the seed is just the initial
/// configuration — determinism follows from folding pure [apply] calls.
GameState replay({
  required Ruleset ruleset,
  required Side firstTurn,
  required List<GameAction> actions,
  String matchId = 'replay',
}) {
  var state = GameState.initial(ruleset: ruleset, firstTurn: firstTurn);
  for (var i = 0; i < actions.length; i++) {
    state = apply(state, actions[i], matchId: matchId, actionSequence: i).state;
  }
  return state;
}

/// Same as [replay] but also returns every [MoveEvent] produced along the
/// way, for presentation-timeline reconstruction and replay verification.
({GameState state, List<MoveEvent> events}) replayWithEvents({
  required Ruleset ruleset,
  required Side firstTurn,
  required List<GameAction> actions,
  String matchId = 'replay',
}) {
  var state = GameState.initial(ruleset: ruleset, firstTurn: firstTurn);
  final events = <MoveEvent>[];
  for (var i = 0; i < actions.length; i++) {
    final outcome = apply(
      state,
      actions[i],
      matchId: matchId,
      actionSequence: i,
    );
    state = outcome.state;
    events.add(outcome.event);
  }
  return (state: state, events: events);
}

/// Structural invariant checks used by tests (and safe to call from debug
/// assertions). Returns an empty list when [state] is well-formed.
List<String> validateInvariants(GameState state) {
  final violations = <String>[];

  for (final node in state.pieces.keys) {
    if (!state.graph.isValidNode(node)) {
      violations.add('Piece occupies undeclared node: $node');
    }
  }

  final topCount = state.pieces.values.where((s) => s == Side.top).length;
  final bottomCount = state.pieces.values.where((s) => s == Side.bottom).length;
  if (topCount < 0 || bottomCount < 0 || topCount + bottomCount > 24) {
    violations.add(
      'Implausible piece counts: top=$topCount bottom=$bottomCount',
    );
  }

  if (state.mustContinueCaptureFrom != null) {
    final node = state.mustContinueCaptureFrom!;
    if (state.pieces[node] != state.turn) {
      violations.add(
        'mustContinueCaptureFrom=$node is not occupied by the side to move',
      );
    } else if (_capturesFromNode(
      state.graph,
      state.pieces,
      node,
      state.turn,
    ).isEmpty) {
      violations.add('mustContinueCaptureFrom=$node has no available capture');
    }
  }

  if (state.phase == GamePhase.finished && legalActions(state).isNotEmpty) {
    violations.add('Finished state still reports legal Move/Capture actions');
  }

  return violations;
}

// --- Internal helpers -------------------------------------------------

List<CaptureAction> _capturesFromNode(
  BoardGraph graph,
  Map<NodeId, Side> pieces,
  NodeId node,
  Side side,
) {
  final result = <CaptureAction>[];
  for (final jump in graph.jumpsFrom(node)) {
    final overSide = pieces[jump.over];
    final landingOccupied = pieces.containsKey(jump.landing);
    if (overSide != null && overSide != side && !landingOccupied) {
      result.add(
        CaptureAction(from: jump.source, over: jump.over, to: jump.landing),
      );
    }
  }
  return result;
}

List<CaptureAction> _allCaptures(
  BoardGraph graph,
  Map<NodeId, Side> pieces,
  Side side,
) {
  final result = <CaptureAction>[];
  for (final entry in pieces.entries) {
    if (entry.value == side) {
      result.addAll(_capturesFromNode(graph, pieces, entry.key, side));
    }
  }
  return result;
}

List<MoveAction> _allMoves(
  BoardGraph graph,
  Map<NodeId, Side> pieces,
  Side side,
) {
  final result = <MoveAction>[];
  for (final entry in pieces.entries) {
    if (entry.value != side) continue;
    for (final neighbor in graph.neighborsOf(entry.key)) {
      if (!pieces.containsKey(neighbor)) {
        result.add(MoveAction(from: entry.key, to: neighbor));
      }
    }
  }
  return result;
}

ActionOutcome _applyMove(
  GameState state, {
  required NodeId from,
  required NodeId to,
  required String matchId,
  required int actionSequence,
}) {
  final newPieces = Map<NodeId, Side>.from(state.pieces);
  final mover = newPieces.remove(from)!;
  newPieces[to] = mover;

  var next = GameState(
    graph: state.graph,
    pieces: Map.unmodifiable(newPieces),
    turn: state.turn.opponent,
    ruleset: state.ruleset,
    phase: GamePhase.playing,
    winner: null,
    winReason: null,
    isDraw: false,
    mustContinueCaptureFrom: null,
    chainStepIndex: 0,
    plyCount: state.plyCount + 1,
    pliesSinceLastCapture: state.pliesSinceLastCapture + 1,
  );
  next = _checkTerminal(next);

  final event = MoveEvent(
    matchId: matchId,
    actionSequence: actionSequence,
    actor: state.turn,
    actionType: 'move',
    source: from,
    destination: to,
    capturedNodes: const [],
    chainStep: 0,
    chainContinues: false,
    resultingTurn: next.turn,
    rulesetId: state.ruleset.id,
    rulesetVersion: state.ruleset.version,
  );
  return ActionOutcome(state: next, event: event);
}

ActionOutcome _applyCapture(
  GameState state, {
  required NodeId from,
  required NodeId over,
  required NodeId to,
  required String matchId,
  required int actionSequence,
}) {
  final newPieces = Map<NodeId, Side>.from(state.pieces);
  final mover = newPieces.remove(from)!;
  newPieces.remove(over);
  newPieces[to] = mover;

  final furtherCaptures = state.ruleset.chainCaptureMandatory
      ? _capturesFromNode(state.graph, newPieces, to, state.turn)
      : const <CaptureAction>[];
  final continues = furtherCaptures.isNotEmpty;

  var next = GameState(
    graph: state.graph,
    pieces: Map.unmodifiable(newPieces),
    turn: continues ? state.turn : state.turn.opponent,
    ruleset: state.ruleset,
    phase: GamePhase.playing,
    winner: null,
    winReason: null,
    isDraw: false,
    mustContinueCaptureFrom: continues ? to : null,
    chainStepIndex: continues ? state.chainStepIndex + 1 : 0,
    plyCount: state.plyCount + 1,
    pliesSinceLastCapture: 0,
  );
  next = _checkTerminal(next);

  final event = MoveEvent(
    matchId: matchId,
    actionSequence: actionSequence,
    actor: state.turn,
    actionType: 'capture',
    source: from,
    destination: to,
    capturedNodes: [over],
    chainStep: state.chainStepIndex,
    chainContinues: continues,
    resultingTurn: next.turn,
    rulesetId: state.ruleset.id,
    rulesetVersion: state.ruleset.version,
  );
  return ActionOutcome(state: next, event: event);
}

ActionOutcome _applyTermination(
  GameState state, {
  required Side actor,
  required String actionType,
  required Side winner,
  required WinReason winReason,
  required String matchId,
  required int actionSequence,
}) {
  final next = state.finished(winner: winner, winReason: winReason);
  final event = MoveEvent(
    matchId: matchId,
    actionSequence: actionSequence,
    actor: actor,
    actionType: actionType,
    source: null,
    destination: null,
    capturedNodes: const [],
    chainStep: 0,
    chainContinues: false,
    resultingTurn: next.turn,
    rulesetId: state.ruleset.id,
    rulesetVersion: state.ruleset.version,
  );
  return ActionOutcome(state: next, event: event);
}

GameState _checkTerminal(GameState state) {
  if (state.phase != GamePhase.playing) return state;

  final ruleset = state.ruleset;
  if (ruleset.noCaptureMoveLimitForDraw > 0 &&
      state.pliesSinceLastCapture >= ruleset.noCaptureMoveLimitForDraw) {
    return state.finished(isDraw: true);
  }

  final sideToMoveHasPieces = state.pieces.values.any(
    (side) => side == state.turn,
  );
  if (!sideToMoveHasPieces) {
    return state.finished(
      winner: state.turn.opponent,
      winReason: WinReason.elimination,
    );
  }

  if (state.mustContinueCaptureFrom == null && legalActions(state).isEmpty) {
    if (ruleset.stalemateIsLossForPlayerToMove) {
      return state.finished(
        winner: state.turn.opponent,
        winReason: WinReason.noLegalMoves,
      );
    }
    return state.finished(isDraw: true);
  }

  return state;
}
