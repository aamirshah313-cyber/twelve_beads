import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'match_history_repository.dart';
import 'match_record.dart';

/// Overridden in `main.dart` once the repository has been created
/// asynchronously, before the app is run.
final matchHistoryRepositoryProvider = Provider<MatchHistoryRepository>((ref) {
  throw UnimplementedError(
    'matchHistoryRepositoryProvider must be overridden in main()',
  );
});

/// Most-recent-last list of finalized matches for the local profile.
class MatchHistoryController extends Notifier<List<MatchRecord>> {
  @override
  List<MatchRecord> build() => ref.read(matchHistoryRepositoryProvider).load();

  void addRecord(MatchRecord record) {
    state = [...state, record];
    ref.read(matchHistoryRepositoryProvider).save(state);
  }

  Future<void> deleteAllAndReset() async {
    await ref.read(matchHistoryRepositoryProvider).deleteAll();
    state = const [];
  }
}

final matchHistoryControllerProvider =
    NotifierProvider<MatchHistoryController, List<MatchRecord>>(
      MatchHistoryController.new,
    );
