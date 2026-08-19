import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twelve_beads/core/history/match_history_repository.dart';
import 'package:twelve_beads/core/history/match_record.dart';
import 'package:twelve_beads/game/ai/difficulty.dart';
import 'package:twelve_beads/game/board/board_graph.dart';
import 'package:twelve_beads/game/engine/game_state.dart';
import 'package:twelve_beads/game/engine/ruleset.dart';
import 'package:twelve_beads/game/engine/side.dart';

MatchRecord _record({
  String id = 'match-1',
  MatchMode mode = MatchMode.twoPlayer,
  MatchOutcome outcome = MatchOutcome.win,
}) => MatchRecord(
  id: id,
  startedAt: DateTime(2026, 1, 1, 10, 0),
  endedAt: DateTime(2026, 1, 1, 10, 15),
  mode: mode,
  difficulty: mode == MatchMode.vsMachine ? Difficulty.medium : null,
  playerOneName: 'Alice',
  playerTwoName: mode == MatchMode.vsMachine ? 'Machine' : 'Bilal',
  outcome: outcome,
  winReason: WinReason.elimination,
  moveCount: 20,
  ownCaptures: 4,
);

GameState _finishedState({Side? winner, bool isDraw = false}) => GameState(
  graph: BoardGraph.standard(),
  pieces: const {},
  turn: Side.top,
  ruleset: Ruleset.classicAlquerque,
  phase: GamePhase.finished,
  winner: winner,
  winReason: winner != null ? WinReason.elimination : null,
  isDraw: isDraw,
  mustContinueCaptureFrom: null,
  chainStepIndex: 0,
  plyCount: 10,
  pliesSinceLastCapture: 0,
);

void main() {
  group('matchOutcomeFor', () {
    test('own side winning is a win', () {
      expect(
        matchOutcomeFor(_finishedState(winner: Side.top), Side.top),
        MatchOutcome.win,
      );
    });

    test('opponent winning is a loss', () {
      expect(
        matchOutcomeFor(_finishedState(winner: Side.bottom), Side.top),
        MatchOutcome.loss,
      );
    });

    test('a draw is a draw regardless of side', () {
      expect(
        matchOutcomeFor(_finishedState(isDraw: true), Side.top),
        MatchOutcome.draw,
      );
    });
  });

  group('MatchRecord JSON round trip', () {
    test('two-player record survives toJson/fromJson', () {
      final record = _record();
      final restored = MatchRecord.fromJson(record.toJson());
      expect(restored.id, record.id);
      expect(restored.startedAt, record.startedAt);
      expect(restored.endedAt, record.endedAt);
      expect(restored.mode, record.mode);
      expect(restored.difficulty, isNull);
      expect(restored.outcome, record.outcome);
      expect(restored.winReason, record.winReason);
      expect(restored.moveCount, record.moveCount);
      expect(restored.ownCaptures, record.ownCaptures);
      expect(restored.duration, const Duration(minutes: 15));
    });

    test('vs-machine record preserves difficulty', () {
      final record = _record(mode: MatchMode.vsMachine);
      final restored = MatchRecord.fromJson(record.toJson());
      expect(restored.mode, MatchMode.vsMachine);
      expect(restored.difficulty, Difficulty.medium);
    });
  });

  group('MatchHistoryRepository', () {
    test('load returns empty list when nothing is stored', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = await MatchHistoryRepository.create();
      expect(repo.load(), isEmpty);
    });

    test('save then load round-trips the full list in order', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = await MatchHistoryRepository.create();
      final records = [
        _record(id: 'match-1'),
        _record(id: 'match-2', outcome: MatchOutcome.loss),
      ];
      await repo.save(records);
      final loaded = repo.load();
      expect(loaded.map((r) => r.id), ['match-1', 'match-2']);
    });

    test(
      'a corrupted single entry is skipped without losing the rest',
      () async {
        SharedPreferences.setMockInitialValues({
          'match_history.default.v1': [
            '{not valid json',
            jsonEncode({'id': 'match-2'}), // missing required fields
            jsonEncode(_record(id: 'match-3').toJson()),
          ],
        });
        final repo = await MatchHistoryRepository.create();
        final loaded = repo.load();
        expect(loaded.map((r) => r.id), ['match-3']);
      },
    );

    test('save caps the list to maxEntries, keeping the most recent', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = await MatchHistoryRepository.create();
      final records = [
        for (var i = 0; i < MatchHistoryRepository.maxEntries + 10; i++)
          _record(id: 'match-$i'),
      ];
      await repo.save(records);
      final loaded = repo.load();
      expect(loaded.length, MatchHistoryRepository.maxEntries);
      expect(loaded.first.id, 'match-10');
      expect(loaded.last.id, 'match-${records.length - 1}');
    });

    test('deleteAll clears the stored history', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = await MatchHistoryRepository.create();
      await repo.save([_record()]);
      await repo.deleteAll();
      expect(repo.load(), isEmpty);
    });
  });
}
