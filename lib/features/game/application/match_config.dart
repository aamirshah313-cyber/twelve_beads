import '../../../game/engine/ruleset.dart';
import '../../../game/engine/side.dart';

/// Configuration collected on the pre-game setup screen for a local
/// two-player match. Vs-Machine mode isn't covered here yet — the AI
/// opponent is a later phase.
class MatchConfig {
  final String playerOneName;
  final String playerTwoName;

  /// Which [Side] Player 1 controls; Player 2 controls the other.
  final Side playerOneSide;
  final Side firstTurn;
  final Ruleset ruleset;

  /// Total time per player, in minutes. 0 means the timer is off.
  final int timerMinutes;

  const MatchConfig({
    required this.playerOneName,
    required this.playerTwoName,
    required this.playerOneSide,
    required this.firstTurn,
    this.ruleset = Ruleset.classicAlquerque,
    required this.timerMinutes,
  });

  String nameForSide(Side side) =>
      side == playerOneSide ? playerOneName : playerTwoName;

  bool get timerEnabled => timerMinutes > 0;
}
