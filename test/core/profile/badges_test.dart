import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_beads/core/history/match_record.dart';
import 'package:twelve_beads/core/profile/badges.dart';
import 'package:twelve_beads/core/profile/profile_stats.dart';

ProfileStats _stats({
  int matchesPlayed = 0,
  int wins = 0,
  int draws = 0,
  int currentStreak = 0,
  int totalCaptures = 0,
  List<String> earnedBadgeIds = const [],
}) => ProfileStats(
  displayName: 'Alice',
  matchesPlayed: matchesPlayed,
  wins: wins,
  losses: 0,
  draws: draws,
  currentStreak: currentStreak,
  totalCaptures: totalCaptures,
  earnedBadgeIds: earnedBadgeIds,
);

void main() {
  group('evaluateBadges', () {
    test('awards First Win only on a win when no prior wins exist', () {
      final before = _stats();
      final after = _stats(matchesPlayed: 1, wins: 1, currentStreak: 1);
      final earned = evaluateBadges(
        before: before,
        after: after,
        outcome: MatchOutcome.win,
        moveCount: 20,
      );
      expect(earned, contains(BadgeIds.firstWin));
    });

    test('does not re-award First Win once already earned', () {
      final before = _stats(wins: 1, earnedBadgeIds: [BadgeIds.firstWin]);
      final after = _stats(matchesPlayed: 2, wins: 2, currentStreak: 2);
      final earned = evaluateBadges(
        before: before,
        after: after,
        outcome: MatchOutcome.win,
        moveCount: 20,
      );
      expect(earned, isNot(contains(BadgeIds.firstWin)));
    });

    test('does not award First Win on a loss', () {
      final before = _stats();
      final after = _stats(matchesPlayed: 1, currentStreak: 0);
      final earned = evaluateBadges(
        before: before,
        after: after,
        outcome: MatchOutcome.loss,
        moveCount: 20,
      );
      expect(earned, isNot(contains(BadgeIds.firstWin)));
    });

    test('awards Five Matches exactly when the threshold is crossed', () {
      final before = _stats(matchesPlayed: 4);
      final after = _stats(matchesPlayed: 5);
      final earned = evaluateBadges(
        before: before,
        after: after,
        outcome: MatchOutcome.loss,
        moveCount: 20,
      );
      expect(earned, contains(BadgeIds.fiveMatches));
    });

    test('awards Capture Specialist when 5+ captures happen in one match', () {
      final before = _stats(totalCaptures: 2);
      final after = _stats(totalCaptures: 8); // 6 captures this match
      final earned = evaluateBadges(
        before: before,
        after: after,
        outcome: MatchOutcome.loss,
        moveCount: 20,
      );
      expect(earned, contains(BadgeIds.captureSpecialist));
    });

    test('does not award Capture Specialist under the threshold', () {
      final before = _stats(totalCaptures: 2);
      final after = _stats(totalCaptures: 5); // 3 captures this match
      final earned = evaluateBadges(
        before: before,
        after: after,
        outcome: MatchOutcome.loss,
        moveCount: 20,
      );
      expect(earned, isNot(contains(BadgeIds.captureSpecialist)));
    });

    test('awards Three-Win Streak once the streak reaches 3', () {
      final before = _stats(currentStreak: 2);
      final after = _stats(currentStreak: 3);
      final earned = evaluateBadges(
        before: before,
        after: after,
        outcome: MatchOutcome.win,
        moveCount: 20,
      );
      expect(earned, contains(BadgeIds.threeWinStreak));
    });

    test('awards Fast Finish for a short win, not a short loss', () {
      final before = _stats();
      final afterWin = _stats(matchesPlayed: 1, wins: 1, currentStreak: 1);
      final winEarned = evaluateBadges(
        before: before,
        after: afterWin,
        outcome: MatchOutcome.win,
        moveCount: 10,
      );
      expect(winEarned, contains(BadgeIds.fastFinish));

      final afterLoss = _stats(matchesPlayed: 1);
      final lossEarned = evaluateBadges(
        before: before,
        after: afterLoss,
        outcome: MatchOutcome.loss,
        moveCount: 10,
      );
      expect(lossEarned, isNot(contains(BadgeIds.fastFinish)));
    });

    test('awards Patient Player for a long match regardless of outcome', () {
      final before = _stats();
      final after = _stats(matchesPlayed: 1, draws: 1);
      final earned = evaluateBadges(
        before: before,
        after: after,
        outcome: MatchOutcome.draw,
        moveCount: 65,
      );
      expect(earned, contains(BadgeIds.patientPlayer));
    });

    test('awards nothing for an unremarkable mid-streak loss', () {
      final before = _stats(
        matchesPlayed: 10,
        wins: 5,
        currentStreak: 1,
        earnedBadgeIds: [BadgeIds.firstWin, BadgeIds.fiveMatches],
      );
      final after = _stats(matchesPlayed: 11, wins: 5, currentStreak: 0);
      final earned = evaluateBadges(
        before: before,
        after: after,
        outcome: MatchOutcome.loss,
        moveCount: 25,
      );
      expect(earned, isEmpty);
    });
  });
}
