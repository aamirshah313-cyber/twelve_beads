import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twelve_beads/features/game/application/match_config.dart';
import 'package:twelve_beads/features/game/application/saved_game.dart';
import 'package:twelve_beads/features/game/application/saved_game_repository.dart';
import 'package:twelve_beads/game/ai/difficulty.dart';
import 'package:twelve_beads/game/engine/game_action.dart';
import 'package:twelve_beads/game/engine/side.dart';

void main() {
  group('MatchConfig JSON round trip', () {
    test('a two-player config survives toJson/fromJson', () {
      const config = MatchConfig(
        playerOneName: 'Alice',
        playerTwoName: 'Bilal',
        playerOneSide: Side.top,
        firstTurn: Side.bottom,
        timerMinutes: 5,
        perMoveSeconds: 30,
      );
      final restored = MatchConfig.fromJson(config.toJson());

      expect(restored.playerOneName, config.playerOneName);
      expect(restored.playerTwoName, config.playerTwoName);
      expect(restored.playerOneSide, config.playerOneSide);
      expect(restored.firstTurn, config.firstTurn);
      expect(restored.ruleset.id, config.ruleset.id);
      expect(restored.timerMinutes, config.timerMinutes);
      expect(restored.perMoveSeconds, config.perMoveSeconds);
      expect(restored.machineSide, isNull);
      expect(restored.isVsMachine, isFalse);
    });

    test('a vs-machine config preserves machineSide and difficulty', () {
      const config = MatchConfig(
        playerOneName: 'Alice',
        playerTwoName: 'Machine',
        playerOneSide: Side.top,
        firstTurn: Side.top,
        timerMinutes: 0,
        machineSide: Side.bottom,
        difficulty: Difficulty.difficult,
      );
      final restored = MatchConfig.fromJson(config.toJson());

      expect(restored.isVsMachine, isTrue);
      expect(restored.machineSide, Side.bottom);
      expect(restored.difficulty, Difficulty.difficult);
    });

    test('perMoveSeconds defaults to 0 (off) when absent from stored JSON', () {
      // Simulates data saved before per-move timers existed (schema v1).
      const config = MatchConfig(
        playerOneName: 'Alice',
        playerTwoName: 'Bilal',
        playerOneSide: Side.top,
        firstTurn: Side.top,
        timerMinutes: 5,
      );
      final json = config.toJson()..remove('perMoveSeconds');
      final restored = MatchConfig.fromJson(json);

      expect(restored.perMoveSeconds, 0);
      expect(restored.perMoveTimerEnabled, isFalse);
    });
  });

  group('SavedGameSnapshot JSON round trip', () {
    SavedGameSnapshot snapshot({Duration? perMoveRemaining}) =>
        SavedGameSnapshot(
          config: const MatchConfig(
            playerOneName: 'Alice',
            playerTwoName: 'Bilal',
            playerOneSide: Side.top,
            firstTurn: Side.top,
            timerMinutes: 5,
            perMoveSeconds: 30,
          ),
          actionLog: const [
            MoveAction(from: 'r1c2', to: 'r2c2'),
            CaptureAction(from: 'r3c2', over: 'r2c2', to: 'r1c2'),
          ],
          topRemaining: const Duration(minutes: 4, seconds: 10),
          bottomRemaining: const Duration(minutes: 5),
          perMoveRemaining: perMoveRemaining,
          startedAt: DateTime(2026, 1, 1, 9),
          savedAt: DateTime(2026, 1, 1, 9, 12),
        );

    test('a snapshot with a per-move remaining value round-trips exactly', () {
      final original = snapshot(perMoveRemaining: const Duration(seconds: 18));
      final restored = SavedGameSnapshot.fromJson(original.toJson());

      expect(restored.actionLog, original.actionLog);
      expect(restored.topRemaining, original.topRemaining);
      expect(restored.bottomRemaining, original.bottomRemaining);
      expect(restored.perMoveRemaining, original.perMoveRemaining);
      expect(restored.startedAt, original.startedAt);
      expect(restored.savedAt, original.savedAt);
      expect(restored.config.perMoveSeconds, 30);
    });

    test('a snapshot with no per-move timer round-trips a null value', () {
      final original = snapshot();
      final restored = SavedGameSnapshot.fromJson(original.toJson());
      expect(restored.perMoveRemaining, isNull);
    });
  });

  group('SavedGameRepository — real storage round trip', () {
    test(
      'save then load through actual SharedPreferences-backed storage '
      'reconstructs an identical snapshot (not just the in-memory object)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final repo = await SavedGameRepository.create();

        const config = MatchConfig(
          playerOneName: 'Alice',
          playerTwoName: 'Machine',
          playerOneSide: Side.top,
          firstTurn: Side.top,
          timerMinutes: 3,
          perMoveSeconds: 45,
          machineSide: Side.bottom,
          difficulty: Difficulty.medium,
        );
        final saved = SavedGameSnapshot(
          config: config,
          actionLog: const [MoveAction(from: 'r1c2', to: 'r2c2')],
          topRemaining: const Duration(minutes: 2, seconds: 30),
          bottomRemaining: const Duration(minutes: 3),
          perMoveRemaining: const Duration(seconds: 20),
          startedAt: DateTime(2026, 2, 1, 8),
          savedAt: DateTime(2026, 2, 1, 8, 5),
        );

        await repo.save(saved);

        // A fresh repository instance reading the same (mocked)
        // SharedPreferences store simulates surviving an app restart —
        // unlike reusing `repo` itself, or passing the in-memory `saved`
        // object directly.
        final reloaded = await SavedGameRepository.create();
        final loaded = reloaded.load();

        expect(loaded, isNotNull);
        expect(loaded!.config.playerOneName, 'Alice');
        expect(loaded.config.isVsMachine, isTrue);
        expect(loaded.config.machineSide, Side.bottom);
        expect(loaded.config.perMoveSeconds, 45);
        expect(loaded.actionLog, saved.actionLog);
        expect(loaded.topRemaining, saved.topRemaining);
        expect(loaded.perMoveRemaining, const Duration(seconds: 20));
      },
    );

    test('load returns null when nothing has been saved', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = await SavedGameRepository.create();
      expect(repo.load(), isNull);
    });

    test('a corrupted stored value is discarded, not crashed on', () async {
      SharedPreferences.setMockInitialValues({
        'saved_game.default.v1': '{not valid json',
      });
      final repo = await SavedGameRepository.create();
      expect(repo.load(), isNull);
    });

    test('clear removes the stored snapshot', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = await SavedGameRepository.create();
      const config = MatchConfig(
        playerOneName: 'Alice',
        playerTwoName: 'Bilal',
        playerOneSide: Side.top,
        firstTurn: Side.top,
        timerMinutes: 0,
      );
      await repo.save(
        SavedGameSnapshot(
          config: config,
          actionLog: const [],
          topRemaining: Duration.zero,
          bottomRemaining: Duration.zero,
          startedAt: DateTime(2026, 1, 1),
          savedAt: DateTime(2026, 1, 1),
        ),
      );
      await repo.clear();
      expect(repo.load(), isNull);
    });
  });
}
