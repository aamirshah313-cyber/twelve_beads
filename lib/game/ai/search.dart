import '../engine/game_action.dart';
import '../engine/game_state.dart';
import '../engine/rules_engine.dart';
import 'evaluation.dart';

/// Thrown internally to unwind an iterative-deepening search once its time
/// budget has been exceeded mid-iteration — the partially-explored depth is
/// discarded, keeping only the last depth that finished cleanly.
class SearchTimeout implements Exception {
  const SearchTimeout();
}

class SearchResult {
  final GameAction? action;
  final int score;
  const SearchResult({required this.action, required this.score});
}

/// Orders legal actions to help alpha-beta pruning: captures first (they
/// tend to be forcing), then everything else in declared order.
List<GameAction> orderedActions(
  List<GameAction> actions, {
  GameAction? preferred,
}) {
  final ordered = [...actions];
  ordered.sort((a, b) {
    if (preferred != null) {
      if (a == preferred) return -1;
      if (b == preferred) return 1;
    }
    final aIsCapture = a is CaptureAction;
    final bIsCapture = b is CaptureAction;
    if (aIsCapture == bIsCapture) return 0;
    return aIsCapture ? -1 : 1;
  });
  return ordered;
}

/// Fixed-depth negamax with alpha-beta pruning. Chained captures (where the
/// same side must continue, per `mustContinueCaptureFrom`) do not flip the
/// evaluation perspective or consume a ply — only an actual turn change
/// does, matching how forced chains work in this ruleset.
SearchResult negamaxSearch(
  GameState state,
  int depth, {
  int alpha = -terminalScoreMagnitude * 2,
  int beta = terminalScoreMagnitude * 2,
  int pliesFromRoot = 0,
  GameAction? preferredRootAction,
  Map<String, TranspositionEntry>? transpositionTable,
  DateTime Function()? clockNow,
  DateTime? deadline,
}) {
  if (deadline != null && clockNow != null && !clockNow().isBefore(deadline)) {
    throw const SearchTimeout();
  }

  final outcome = result(state);
  if (outcome.isOver || depth <= 0) {
    return SearchResult(
      action: null,
      score: evaluateForMover(state, pliesFromRoot: pliesFromRoot),
    );
  }

  String? ttKey;
  final tt = transpositionTable;
  if (tt != null) {
    ttKey = _stateKey(state);
    final cached = tt[ttKey];
    if (cached != null && cached.depth >= depth) {
      return SearchResult(action: cached.action, score: cached.score);
    }
  }

  final actions = legalActions(state);
  if (actions.isEmpty) {
    return SearchResult(
      action: null,
      score: evaluateForMover(state, pliesFromRoot: pliesFromRoot),
    );
  }

  GameAction? bestAction;
  var bestScore = -terminalScoreMagnitude * 2;
  var fullyExplored = true;
  var currentAlpha = alpha;

  for (final action in orderedActions(
    actions,
    preferred: preferredRootAction,
  )) {
    final child = apply(
      state,
      action,
      matchId: 'ai-search',
      actionSequence: 0,
    ).state;
    final sameMoverContinues =
        child.phase == GamePhase.playing && child.turn == state.turn;

    final int score;
    if (sameMoverContinues) {
      final childResult = negamaxSearch(
        child,
        depth,
        alpha: currentAlpha,
        beta: beta,
        pliesFromRoot: pliesFromRoot,
        transpositionTable: transpositionTable,
        clockNow: clockNow,
        deadline: deadline,
      );
      score = childResult.score;
    } else {
      final childResult = negamaxSearch(
        child,
        depth - 1,
        alpha: -beta,
        beta: -currentAlpha,
        pliesFromRoot: pliesFromRoot + 1,
        transpositionTable: transpositionTable,
        clockNow: clockNow,
        deadline: deadline,
      );
      score = -childResult.score;
    }

    if (score > bestScore) {
      bestScore = score;
      bestAction = action;
    }
    if (bestScore > currentAlpha) currentAlpha = bestScore;
    if (currentAlpha >= beta) {
      fullyExplored = false; // pruned — don't cache as an exact score
      break;
    }
  }

  if (ttKey != null && fullyExplored) {
    tt![ttKey] = TranspositionEntry(
      depth: depth,
      score: bestScore,
      action: bestAction,
    );
  }

  return SearchResult(action: bestAction, score: bestScore);
}

/// Iterative deepening on top of [negamaxSearch]: searches depth 1, 2, 3...
/// keeping the best action from the last depth that finished inside
/// [timeBudget], with move ordering seeded by the previous depth's best
/// action and a shared transposition cache across depths.
SearchResult iterativeDeepeningSearch(
  GameState state, {
  required Duration timeBudget,
  required DateTime Function() clockNow,
  int maxDepth = 12,
}) {
  final deadline = clockNow().add(timeBudget);
  final transpositionTable = <String, TranspositionEntry>{};

  SearchResult? lastCompleted;
  GameAction? preferredRootAction;

  for (var depth = 1; depth <= maxDepth; depth++) {
    try {
      final result = negamaxSearch(
        state,
        depth,
        preferredRootAction: preferredRootAction,
        transpositionTable: transpositionTable,
        clockNow: clockNow,
        deadline: deadline,
      );
      lastCompleted = result;
      preferredRootAction = result.action;
      if (!clockNow().isBefore(deadline)) break;
    } on SearchTimeout {
      break;
    }
  }

  return lastCompleted ??
      SearchResult(action: legalActions(state).first, score: 0);
}

class TranspositionEntry {
  final int depth;
  final int score;
  final GameAction? action;
  const TranspositionEntry({
    required this.depth,
    required this.score,
    required this.action,
  });
}

String _stateKey(GameState state) {
  final pieces =
      state.pieces.entries.map((e) => '${e.key}:${e.value.name}').toList()
        ..sort();
  return '${state.turn.name}|${state.mustContinueCaptureFrom}|${pieces.join(',')}';
}
