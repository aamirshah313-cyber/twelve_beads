import 'package:shared_preferences/shared_preferences.dart';
import 'package:twelve_beads/core/history/match_history_repository.dart';
import 'package:twelve_beads/core/profile/profile_repository.dart';
import 'package:twelve_beads/core/settings/settings_repository.dart';
import 'package:twelve_beads/features/game/application/saved_game_repository.dart';

/// Every test that exercises `MatchController`/`MachineController` needs a
/// full set of in-memory-backed repositories (settings, profile, match
/// history, saved game — Phase 6 wired all of these into match
/// finalization/autosave). `Override` isn't a publicly exported type in
/// Riverpod 3.x, so this can't return a ready-made overrides list; instead
/// it centralizes just the repository construction, and each call site
/// builds its own `overrides: [...]` list from the fields here (letting the
/// list literal's type be inferred, per the pattern established in
/// match_controller_test.dart).
class TestRepositories {
  const TestRepositories({
    required this.settings,
    required this.profile,
    required this.matchHistory,
    required this.savedGame,
  });

  final SettingsRepository settings;
  final ProfileRepository profile;
  final MatchHistoryRepository matchHistory;
  final SavedGameRepository savedGame;
}

Future<TestRepositories> createTestRepositories() async {
  SharedPreferences.setMockInitialValues({});
  return TestRepositories(
    settings: await SettingsRepository.create(),
    profile: await ProfileRepository.create(),
    matchHistory: await MatchHistoryRepository.create(),
    savedGame: await SavedGameRepository.create(),
  );
}
