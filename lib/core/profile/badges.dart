import '../history/match_record.dart';
import 'profile_stats.dart';

/// Stable badge identifiers, persisted in [ProfileStats.earnedBadgeIds].
/// Never renamed once shipped — only the localized label/description shown
/// for an id may change.
class BadgeIds {
  static const firstWin = 'first_win';
  static const fiveMatches = 'five_matches';
  static const captureSpecialist = 'capture_specialist';
  static const threeWinStreak = 'three_win_streak';
  static const fastFinish = 'fast_finish';
  static const patientPlayer = 'patient_player';

  static const all = [
    firstWin,
    fiveMatches,
    captureSpecialist,
    threeWinStreak,
    fastFinish,
    patientPlayer,
  ];
}

/// Sensible, documented-as-arbitrary thresholds (see docs/spec/DECISIONS.md)
/// for the badge examples listed in 03-architecture-and-data.md, in the
/// absence of a specified source for exact numbers.
const _captureSpecialistThreshold = 5;
const _fastFinishMaxMoves = 12;
const _patientPlayerMinMoves = 60;

/// Deterministic, evaluated-once-per-finalized-match badge check. [before]
/// is the profile's stats immediately before this match was folded in,
/// [after] is the stats with this match's result/captures/streak already
/// applied (but before any badge is added) — comparing the two lets a
/// "crossing a threshold" badge (e.g. Five Matches) fire exactly once.
List<String> evaluateBadges({
  required ProfileStats before,
  required ProfileStats after,
  required MatchOutcome outcome,
  required int moveCount,
}) {
  final newlyEarned = <String>[];

  void award(String badgeId, bool condition) {
    if (condition && !before.earnedBadgeIds.contains(badgeId)) {
      newlyEarned.add(badgeId);
    }
  }

  award(BadgeIds.firstWin, outcome == MatchOutcome.win && before.wins == 0);
  award(BadgeIds.fiveMatches, after.matchesPlayed >= 5);
  award(
    BadgeIds.captureSpecialist,
    after.totalCaptures - before.totalCaptures >= _captureSpecialistThreshold,
  );
  award(BadgeIds.threeWinStreak, after.currentStreak >= 3);
  award(
    BadgeIds.fastFinish,
    outcome == MatchOutcome.win && moveCount <= _fastFinishMaxMoves,
  );
  award(BadgeIds.patientPlayer, moveCount >= _patientPlayerMinMoves);

  return newlyEarned;
}
