import '../../../game/engine/game_action.dart';
import 'match_config.dart';

/// A single resumable in-progress match, per the "SavedGame" entity in
/// 03-architecture-and-data.md. Deliberately stores the config + action log
/// rather than a raw board snapshot: the same [replay] used for undo/replay
/// verification reconstructs the exact [GameState], so there is only ever
/// one authoritative way to derive match state from persisted data.
class SavedGameSnapshot {
  static const int schemaVersion = 2;

  final MatchConfig config;
  final List<GameAction> actionLog;
  final Duration topRemaining;
  final Duration bottomRemaining;

  /// Remaining time on the current per-move timer, if
  /// [MatchConfig.perMoveTimerEnabled]; null otherwise.
  final Duration? perMoveRemaining;
  final DateTime startedAt;
  final DateTime savedAt;

  const SavedGameSnapshot({
    required this.config,
    required this.actionLog,
    required this.topRemaining,
    required this.bottomRemaining,
    this.perMoveRemaining,
    required this.startedAt,
    required this.savedAt,
  });

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'config': config.toJson(),
    'actionLog': [for (final action in actionLog) action.toJson()],
    'topRemainingMs': topRemaining.inMilliseconds,
    'bottomRemainingMs': bottomRemaining.inMilliseconds,
    'perMoveRemainingMs': perMoveRemaining?.inMilliseconds,
    'startedAt': startedAt.toIso8601String(),
    'savedAt': savedAt.toIso8601String(),
  };

  factory SavedGameSnapshot.fromJson(Map<String, Object?> json) {
    final perMoveRemainingMs = json['perMoveRemainingMs'] as int?;
    return SavedGameSnapshot(
      config: MatchConfig.fromJson(
        (json['config'] as Map).cast<String, Object?>(),
      ),
      actionLog: [
        for (final entry in json['actionLog'] as List)
          GameAction.fromJson((entry as Map).cast<String, Object?>()),
      ],
      topRemaining: Duration(milliseconds: json['topRemainingMs'] as int),
      bottomRemaining: Duration(milliseconds: json['bottomRemainingMs'] as int),
      perMoveRemaining: perMoveRemainingMs != null
          ? Duration(milliseconds: perMoveRemainingMs)
          : null,
      startedAt: DateTime.parse(json['startedAt'] as String),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}
