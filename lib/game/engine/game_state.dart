import '../board/board_graph.dart';
import 'ruleset.dart';
import 'side.dart';

enum GamePhase { playing, finished }

enum WinReason { elimination, noLegalMoves, resignation, timeout }

/// Immutable game state. Pure Dart, no Flutter imports, no persistence, no
/// timers — per the engine contract in 02-board-rules-and-engine.md.
class GameState {
  final BoardGraph graph;
  final Map<NodeId, Side> pieces;
  final Side turn;
  final Ruleset ruleset;
  final GamePhase phase;
  final Side? winner;
  final WinReason? winReason;
  final bool isDraw;

  /// Non-null while a forced capture chain is in progress: the node the
  /// next capture must originate from. Null when it is a free choice among
  /// [pieces] belonging to [turn].
  final NodeId? mustContinueCaptureFrom;

  /// 0 for the first capture of a turn; increments with each forced chain
  /// continuation. Reset to 0 whenever the turn passes.
  final int chainStepIndex;

  final int plyCount;
  final int pliesSinceLastCapture;

  const GameState({
    required this.graph,
    required this.pieces,
    required this.turn,
    required this.ruleset,
    required this.phase,
    required this.winner,
    required this.winReason,
    required this.isDraw,
    required this.mustContinueCaptureFrom,
    required this.chainStepIndex,
    required this.plyCount,
    required this.pliesSinceLastCapture,
  });

  factory GameState.initial({
    BoardGraph? graph,
    Ruleset ruleset = Ruleset.classicAlquerque,
    Side firstTurn = Side.top,
  }) {
    final resolvedGraph = graph ?? BoardGraph.standard();
    final pieces = <NodeId, Side>{
      for (final node in StandardStartingLayout.topSide) node: Side.top,
      for (final node in StandardStartingLayout.bottomSide) node: Side.bottom,
    };
    return GameState(
      graph: resolvedGraph,
      pieces: Map.unmodifiable(pieces),
      turn: firstTurn,
      ruleset: ruleset,
      phase: GamePhase.playing,
      winner: null,
      winReason: null,
      isDraw: false,
      mustContinueCaptureFrom: null,
      chainStepIndex: 0,
      plyCount: 0,
      pliesSinceLastCapture: 0,
    );
  }

  /// Returns a terminal copy of this state. Only used internally by the
  /// rules engine.
  GameState finished({
    Side? winner,
    WinReason? winReason,
    bool isDraw = false,
  }) {
    return GameState(
      graph: graph,
      pieces: pieces,
      turn: turn,
      ruleset: ruleset,
      phase: GamePhase.finished,
      winner: winner,
      winReason: winReason,
      isDraw: isDraw,
      mustContinueCaptureFrom: null,
      chainStepIndex: chainStepIndex,
      plyCount: plyCount,
      pliesSinceLastCapture: pliesSinceLastCapture,
    );
  }

  Map<String, Object?> toJson() => {
    'boardId': 'standard',
    'pieces': {for (final entry in pieces.entries) entry.key: entry.value.name},
    'turn': turn.name,
    'rulesetId': ruleset.id,
    'rulesetVersion': ruleset.version,
    'phase': phase.name,
    'winner': winner?.name,
    'winReason': winReason?.name,
    'isDraw': isDraw,
    'mustContinueCaptureFrom': mustContinueCaptureFrom,
    'chainStepIndex': chainStepIndex,
    'plyCount': plyCount,
    'pliesSinceLastCapture': pliesSinceLastCapture,
  };

  factory GameState.fromJson(Map<String, Object?> json) {
    if (json['boardId'] != 'standard') {
      throw ArgumentError('Unknown boardId: ${json['boardId']}');
    }
    final ruleset = Ruleset.knownRulesets[json['rulesetId'] as String];
    if (ruleset == null) {
      throw ArgumentError('Unknown rulesetId: ${json['rulesetId']}');
    }
    final piecesJson = (json['pieces'] as Map).cast<String, Object?>();
    final pieces = <NodeId, Side>{
      for (final entry in piecesJson.entries)
        entry.key: Side.values.byName(entry.value as String),
    };
    final winnerName = json['winner'] as String?;
    final winReasonName = json['winReason'] as String?;
    return GameState(
      graph: BoardGraph.standard(),
      pieces: Map.unmodifiable(pieces),
      turn: Side.values.byName(json['turn'] as String),
      ruleset: ruleset,
      phase: GamePhase.values.byName(json['phase'] as String),
      winner: winnerName != null ? Side.values.byName(winnerName) : null,
      winReason: winReasonName != null
          ? WinReason.values.byName(winReasonName)
          : null,
      isDraw: json['isDraw'] as bool? ?? false,
      mustContinueCaptureFrom: json['mustContinueCaptureFrom'] as String?,
      chainStepIndex: json['chainStepIndex'] as int? ?? 0,
      plyCount: json['plyCount'] as int? ?? 0,
      pliesSinceLastCapture: json['pliesSinceLastCapture'] as int? ?? 0,
    );
  }
}
