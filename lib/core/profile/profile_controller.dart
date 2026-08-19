import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> deleteAllAndReset() async {
    await ref.read(profileRepositoryProvider).deleteAll();
    state = ProfileStats.defaultProfile();
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileStats>(ProfileController.new);
