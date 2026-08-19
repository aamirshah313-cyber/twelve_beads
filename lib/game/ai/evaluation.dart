import '../engine/game_action.dart';
import '../engine/game_state.dart';
import '../engine/rules_engine.dart';
import '../engine/side.dart';

/// Score magnitude for a decided (won/lost) position — comfortably larger
/// than any achievable material/mobility swing, and small enough to leave
/// headroom for depth-based tie-breaking (`_terminalScore - depth`) without
/// overflowing.
const terminalScoreMagnitude = 1000000;

/// Evaluates [state] from the perspective of the side whose turn it is
/// (`state.turn`) — the standard negamax convention. Positive is good for
/// the mover. Terminal outcomes are read from [result], never re-derived.
///
/// Every signal here is computed only via the engine's public
/// [legalActions]/[result] functions on [state] or on `state`-derived
/// hypothetical copies (used only to ask "what could the opponent do from
/// here", never fed back through [apply]) — the AI never bypasses the
/// engine to inspect the board directly.
int evaluateForMover(GameState state, {int pliesFromRoot = 0}) {
  final outcome = result(state);
  if (outcome.isOver) {
    if (outcome.isDraw) return 0;
    // Prefer faster wins / slower losses: a mate found sooner scores higher.
    final sign = outcome.winner == state.turn ? 1 : -1;
    return sign * (terminalScoreMagnitude - pliesFromRoot);
  }

  final mover = state.turn;
  final opponent = mover.opponent;

  final myCount = state.pieces.values.where((s) => s == mover).length;
  final opponentCount = state.pieces.values.where((s) => s == opponent).length;
  var score = (myCount - opponentCount) * 100;

  // Mobility: more options now is generally good for the mover.
  score += legalActions(state).length * 4;

  // Threatened pieces: if it were the opponent's turn from this same board,
  // how many captures could they make against the mover? This is a
  // one-ply-lookahead defensive signal, computed via the same public
  // legalActions the engine already exposes — not a rules bypass.
  final opponentView = _withHypotheticalTurn(state, opponent);
  final opponentCaptureThreats = legalActions(opponentView)
      .whereType<CaptureAction>()
      .length;
  score -= opponentCaptureThreats * 35;

  // Mild positional bonus for holding the high-connectivity interior nodes
  // (the inner 3x3 block, degree 8) over the low-connectivity corners.
  for (final entry in state.pieces.entries) {
    final degree = state.graph.neighborsOf(entry.key).length;
    final bonus = degree >= 8 ? 3 : (degree <= 3 ? -1 : 0);
    score += entry.value == mover ? bonus : -bonus;
  }

  return score;
}

GameState _withHypotheticalTurn(GameState state, Side side) {
  return GameState(
    graph: state.graph,
    pieces: state.pieces,
    turn: side,
    ruleset: state.ruleset,
    phase: state.phase,
    winner: state.winner,
    winReason: state.winReason,
    isDraw: state.isDraw,
    mustContinueCaptureFrom: null,
    chainStepIndex: 0,
    plyCount: state.plyCount,
    pliesSinceLastCapture: state.pliesSinceLastCapture,
  );
}
