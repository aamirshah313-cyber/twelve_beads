import '../../game/ai/difficulty.dart';
import '../../game/engine/game_state.dart';
import '../../game/engine/side.dart';

enum MatchMode { twoPlayer, vsMachine }

/// A finished match's result from the local profile's own perspective
/// (always [MatchConfig.playerOneSide] — this app has a single local
/// profile, per Phase 1/6 scope).
enum MatchOutcome { win, loss, draw }

MatchOutcome matchOutcomeFor(GameState finalState, Side ownSide) {
  if (finalState.isDraw) return MatchOutcome.draw;
  return finalState.winner == ownSide ? MatchOutcome.win : MatchOutcome.loss;
}

/// A single finalized match, persisted for the local match-history list.
/// Deliberately stores only summary data (not the full action log) — full
/// replay data is out of scope for Phase 6's history feature; this is
/// documented in docs/spec/DECISIONS.md.
class MatchRecord {
  static const int schemaVersion = 1;

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final MatchMode mode;
  final Difficulty? difficulty;
  final String playerOneName;
  final String playerTwoName;
  final MatchOutcome outcome;
  final WinReason? winReason;
  final int moveCount;
  final int ownCaptures;

  const MatchRecord({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.mode,
    required this.difficulty,
    required this.playerOneName,
    required this.playerTwoName,
    required this.outcome,
    required this.winReason,
    required this.moveCount,
    required this.ownCaptures,
  });

  Duration get duration => endedAt.difference(startedAt);

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'mode': mode.name,
    'difficulty': difficulty?.name,
    'playerOneName': playerOneName,
    'playerTwoName': playerTwoName,
    'outcome': outcome.name,
    'winReason': winReason?.name,
    'moveCount': moveCount,
    'ownCaptures': ownCaptures,
  };

  factory MatchRecord.fromJson(Map<String, Object?> json) {
    final difficultyName = json['difficulty'] as String?;
    final winReasonName = json['winReason'] as String?;
    return MatchRecord(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      mode: MatchMode.values.byName(json['mode'] as String),
      difficulty: difficultyName != null
          ? Difficulty.values.byName(difficultyName)
          : null,
      playerOneName: json['playerOneName'] as String,
      playerTwoName: json['playerTwoName'] as String,
      outcome: MatchOutcome.values.byName(json['outcome'] as String),
      winReason: winReasonName != null
          ? WinReason.values.byName(winReasonName)
          : null,
      moveCount: json['moveCount'] as int,
      ownCaptures: json['ownCaptures'] as int,
    );
  }
}
