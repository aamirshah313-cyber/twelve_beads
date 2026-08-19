import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../history/match_record.dart';
import 'badges.dart';
import 'profile_repository.dart';
import 'profile_stats.dart';

/// Overridden in `main.dart` once the repository has been created
/// asynchronously, before the app is run.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  throw UnimplementedError(
    'profileRepositoryProvider must be overridden in main()',
  );
});

class ProfileController extends Notifier<ProfileStats> {
  @override
  ProfileStats build() {
    return ref.read(profileRepositoryProvider).load();
  }

  void setDisplayName(String name) {
    state = ProfileStats(
      displayName: name,
      matchesPlayed: state.matchesPlayed,
      wins: state.wins,
      losses: state.losses,
      draws: state.draws,
      currentStreak: state.currentStreak,
      totalCaptures: state.totalCaptures,
      earnedBadgeIds: state.earnedBadgeIds,
    );
    ref.read(profileRepositoryProvider).save(state);
  }

  /// Folds one finalized match's result into the aggregate stats, then
  /// evaluates and awards any newly-earned badges. Called exactly once per
  /// finished match, from [MatchController].
  ///
  /// [currentStreak] only ever counts consecutive wins (D-010 in
  /// docs/spec/DECISIONS.md): it resets to 0 on any loss or draw.
  void applyFinalizedMatch({
    required MatchOutcome outcome,
    required int capturesGained,
    required int moveCount,
  }) {
    final before = state;
    final after = ProfileStats(
      displayName: before.displayName,
      matchesPlayed: before.matchesPlayed + 1,
      wins: before.wins + (outcome == MatchOutcome.win ? 1 : 0),
      losses: before.losses + (outcome == MatchOutcome.loss ? 1 : 0),
      draws: before.draws + (outcome == MatchOutcome.draw ? 1 : 0),
      currentStreak: outcome == MatchOutcome.win ? before.currentStreak + 1 : 0,
      totalCaptures: before.totalCaptures + capturesGained,
      earnedBadgeIds: before.earnedBadgeIds,
    );

    final newlyEarned = evaluateBadges(
      before: before,
      after: after,
      outcome: outcome,
      moveCount: moveCount,
    );

    state = newlyEarned.isEmpty
        ? after
        : ProfileStats(
            displayName: after.displayName,
            matchesPlayed: after.matchesPlayed,
            wins: after.wins,
            losses: after.losses,
            draws: after.draws,
            currentStreak: after.currentStreak,
            totalCaptures: after.totalCaptures,
            earnedBadgeIds: [...after.earnedBadgeIds, ...newlyEarned],
          );
    ref.read(profileRepositoryProvider).save(state);
  }

  Future<void> deleteAllAndReset() async {
    await ref.read(profileRepositoryProvider).deleteAll();
    state = ProfileStats.defaultProfile();
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileStats>(ProfileController.new);
