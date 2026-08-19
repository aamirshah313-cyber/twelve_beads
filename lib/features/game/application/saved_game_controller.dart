import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'saved_game.dart';
import 'saved_game_repository.dart';

/// Overridden in `main.dart` once the repository has been created
/// asynchronously, before the app is run.
final savedGameRepositoryProvider = Provider<SavedGameRepository>((ref) {
  throw UnimplementedError(
    'savedGameRepositoryProvider must be overridden in main()',
  );
});

/// The single resumable in-progress match, if any.
class SavedGameController extends Notifier<SavedGameSnapshot?> {
  @override
  SavedGameSnapshot? build() => ref.read(savedGameRepositoryProvider).load();

  void save(SavedGameSnapshot snapshot) {
    state = snapshot;
    ref.read(savedGameRepositoryProvider).save(snapshot);
  }

  void clear() {
    if (state == null) return;
    state = null;
    ref.read(savedGameRepositoryProvider).clear();
  }
}

final savedGameControllerProvider =
    NotifierProvider<SavedGameController, SavedGameSnapshot?>(
      SavedGameController.new,
    );

/// One-shot hand-off slot: the Home screen's "Resume" action stores the
/// snapshot to hydrate here immediately before navigating to [MatchScreen],
/// and the freshly-built `MatchController` consumes (and clears) it in its
/// own `build()`. This avoids threading resume data through `MatchConfig`
/// itself, which stays a plain, JSON-serializable value type.
class PendingResumeSnapshot extends Notifier<SavedGameSnapshot?> {
  @override
  SavedGameSnapshot? build() => null;

  void set(SavedGameSnapshot? snapshot) => state = snapshot;
}

final pendingResumeSnapshotProvider =
    NotifierProvider<PendingResumeSnapshot, SavedGameSnapshot?>(
      PendingResumeSnapshot.new,
    );
