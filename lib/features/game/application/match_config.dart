import '../../../game/ai/difficulty.dart';
import '../../../game/engine/ruleset.dart';
import '../../../game/engine/side.dart';

/// Configuration collected on the pre-game setup screen for a local match —
/// either two human players, or one human against the offline machine
/// opponent.
class MatchConfig {
  final String playerOneName;
  final String playerTwoName;

  /// Which [Side] Player 1 controls; Player 2 (or the machine) controls the
  /// other.
  final Side playerOneSide;
  final Side firstTurn;
  final Ruleset ruleset;

  /// Total time per player, in minutes. 0 means the timer is off.
  final int timerMinutes;

  /// Which side the machine plays, or null for a local two-player match.
  final Side? machineSide;
  final Difficulty difficulty;

  const MatchConfig({
    required this.playerOneName,
    required this.playerTwoName,
    required this.playerOneSide,
    required this.firstTurn,
    this.ruleset = Ruleset.classicAlquerque,
    required this.timerMinutes,
    this.machineSide,
    this.difficulty = Difficulty.medium,
  });

  bool get isVsMachine => machineSide != null;

  /// The configured display name for [side]. When [isVsMachine] and [side]
  /// is [machineSide], callers that need the localized "Machine" label
  /// (screens, which have `AppLocalizations`) check
  /// `isVsMachine && side == machineSide` themselves rather than this
  /// class reaching for a hardcoded string.
  String nameForSide(Side side) =>
      side == playerOneSide ? playerOneName : playerTwoName;

  bool get timerEnabled => timerMinutes > 0;
}
