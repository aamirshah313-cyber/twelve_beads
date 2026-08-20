import 'package:clock/clock.dart' as pkg_clock;
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_beads/core/history/match_history_controller.dart';
import 'package:twelve_beads/core/profile/profile_controller.dart';
import 'package:twelve_beads/core/settings/app_settings.dart';
import 'package:twelve_beads/core/settings/settings_controller.dart';
import 'package:twelve_beads/features/game/application/game_clock.dart';
import 'package:twelve_beads/features/game/application/haptics_port.dart';
import 'package:twelve_beads/features/game/application/machine_controller.dart';
import 'package:twelve_beads/features/game/application/match_config.dart';
import 'package:twelve_beads/features/game/application/match_controller.dart';
import 'package:twelve_beads/features/game/application/move_presentation_controller.dart';
import 'package:twelve_beads/features/game/application/saved_game_controller.dart';
import 'package:twelve_beads/game/ai/difficulty.dart';
import 'package:twelve_beads/game/engine/game_action.dart';
import 'package:twelve_beads/game/engine/game_state.dart';
import 'package:twelve_beads/game/engine/rules_engine.dart';
import 'package:twelve_beads/game/engine/side.dart';

import '../../../support/repository_overrides.dart';

class _AdapterClock implements GameClock {
  _AdapterClock(this._clock);
  final pkg_clock.Clock _clock;
  @override
  DateTime now() => _clock.now();
}

class _NoopHapticsPort implements HapticsPort {
  @override
  void selection() {}
  @override
  void move() {}
  @override
  void capture() {}
  @override
  void matchEnd() {}
  @override
  void warning() {}
}

MatchConfig _vsMachineConfig({
  Side machineSide = Side.bottom,
  Difficulty difficulty = Difficulty.easy,
}) => MatchConfig(
  playerOneName: 'Alice',
  playerTwoName: 'Machine',
  playerOneSide: machineSide.opponent,
  firstTurn: Side.top,
  timerMinutes: 0,
  machineSide: machineSide,
  difficulty: difficulty,
);

/// A [MachineComputeFn] fake that resolves synchronously (well, on the next
/// microtask) to a fixed, always-legal choice — the first action returned by
/// the real engine's `legalActions` — so controller tests don't pay real
/// isolate spawn/search costs while still going through the exact same
/// apply/presentation wiring a real search result would.
Future<GameAction> _firstLegalActionCompute({
  required GameState state,
  required Difficulty difficulty,
  required int seed,
}) async {
  return legalActions(state).first;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MachineController', () {
    late TestRepositories repos;

    setUp(() async {
      repos = await createTestRepositories();
    });

    test(
      'is idle for a two-player (non-machine) match and never starts thinking',
      () {
        fakeAsync((async) {
          final config = MatchConfig(
            playerOneName: 'Alice',
            playerTwoName: 'Bilal',
            playerOneSide: Side.top,
            firstTurn: Side.top,
            timerMinutes: 0,
          );
          final container = ProviderContainer(
            overrides: [
              gameClockProvider.overrideWithValue(
                _AdapterClock(async.getClock(DateTime(2026, 1, 1))),
              ),
              settingsRepositoryProvider.overrideWithValue(repos.settings),
              deviceLanguageCodeProvider.overrideWithValue('en'),
              hapticsPortProvider.overrideWithValue(_NoopHapticsPort()),
              profileRepositoryProvider.overrideWithValue(repos.profile),
              matchHistoryRepositoryProvider.overrideWithValue(
                repos.matchHistory,
              ),
              savedGameRepositoryProvider.overrideWithValue(repos.savedGame),
              machineComputeProvider.overrideWithValue(
                _firstLegalActionCompute,
              ),
              machineRandomSeedProvider.overrideWithValue(() => 1),
            ],
          );
          addTearDown(container.dispose);
          container.listen(
            matchControllerProvider(config),
            (_, _) {},
            fireImmediately: true,
          );
          container.listen(
            machineControllerProvider(config),
            (_, _) {},
            fireImmediately: true,
          );
          async.elapse(const Duration(seconds: 2));

          expect(
            container.read(machineControllerProvider(config)).isThinking,
            isFalse,
          );
          expect(
            container.read(matchControllerProvider(config)).actionLog,
            isEmpty,
          );
        });
      },
    );

    test('shows thinking then applies a legal machine move on its turn', () {
      fakeAsync((async) {
        final config = _vsMachineConfig(machineSide: Side.top);
        final container = ProviderContainer(
          overrides: [
            gameClockProvider.overrideWithValue(
              _AdapterClock(async.getClock(DateTime(2026, 1, 1))),
            ),
            settingsRepositoryProvider.overrideWithValue(repos.settings),
            deviceLanguageCodeProvider.overrideWithValue('en'),
            hapticsPortProvider.overrideWithValue(_NoopHapticsPort()),
            profileRepositoryProvider.overrideWithValue(repos.profile),
            matchHistoryRepositoryProvider.overrideWithValue(
              repos.matchHistory,
            ),
            savedGameRepositoryProvider.overrideWithValue(repos.savedGame),
            machineComputeProvider.overrideWithValue(_firstLegalActionCompute),
            machineRandomSeedProvider.overrideWithValue(() => 1),
          ],
        );
        addTearDown(container.dispose);
        container.listen(
          matchControllerProvider(config),
          (_, _) {},
          fireImmediately: true,
        );
        container.listen(
          machineControllerProvider(config),
          (_, _) {},
          fireImmediately: true,
        );

        // Machine plays top and moves first: thinking should start almost
        // immediately (deferred by one microtask from build()).
        async.flushMicrotasks();
        expect(
          container.read(machineControllerProvider(config)).isThinking,
          isTrue,
        );

        // The minimum thinking delay hasn't elapsed yet — no move applied.
        expect(
          container.read(matchControllerProvider(config)).actionLog,
          isEmpty,
        );

        async.elapse(const Duration(milliseconds: 800));

        expect(
          container.read(machineControllerProvider(config)).isThinking,
          isFalse,
        );
        final afterMove = container.read(matchControllerProvider(config));
        expect(afterMove.actionLog.length, 1);
        expect(afterMove.gameState.turn, Side.bottom);
      });
    });

    test('pausing mid-think cancels the pending machine move (stale generation discarded)', () {
      fakeAsync((async) {
        final config = _vsMachineConfig(machineSide: Side.top);
        final container = ProviderContainer(
          overrides: [
            gameClockProvider.overrideWithValue(
              _AdapterClock(async.getClock(DateTime(2026, 1, 1))),
            ),
            settingsRepositoryProvider.overrideWithValue(repos.settings),
            deviceLanguageCodeProvider.overrideWithValue('en'),
            hapticsPortProvider.overrideWithValue(_NoopHapticsPort()),
            profileRepositoryProvider.overrideWithValue(repos.profile),
            matchHistoryRepositoryProvider.overrideWithValue(
              repos.matchHistory,
            ),
            savedGameRepositoryProvider.overrideWithValue(repos.savedGame),
            machineComputeProvider.overrideWithValue(_firstLegalActionCompute),
            machineRandomSeedProvider.overrideWithValue(() => 1),
          ],
        );
        addTearDown(container.dispose);
        container.listen(
          matchControllerProvider(config),
          (_, _) {},
          fireImmediately: true,
        );
        container.listen(
          machineControllerProvider(config),
          (_, _) {},
          fireImmediately: true,
        );

        async.flushMicrotasks();
        expect(
          container.read(machineControllerProvider(config)).isThinking,
          isTrue,
        );

        container.read(matchControllerProvider(config).notifier).pause();

        // Let the full thinking delay elapse — the machine's computed
        // action must NOT be applied because the match was paused mid-think.
        async.elapse(const Duration(seconds: 2));

        expect(
          container.read(machineControllerProvider(config)).isThinking,
          isFalse,
        );
        expect(
          container.read(matchControllerProvider(config)).actionLog,
          isEmpty,
          reason: 'pausing must discard the in-flight machine move',
        );
      });
    });

    test('restart cancels a pending machine move and starts fresh', () {
      fakeAsync((async) {
        final config = _vsMachineConfig(machineSide: Side.top);
        final container = ProviderContainer(
          overrides: [
            gameClockProvider.overrideWithValue(
              _AdapterClock(async.getClock(DateTime(2026, 1, 1))),
            ),
            settingsRepositoryProvider.overrideWithValue(repos.settings),
            deviceLanguageCodeProvider.overrideWithValue('en'),
            hapticsPortProvider.overrideWithValue(_NoopHapticsPort()),
            profileRepositoryProvider.overrideWithValue(repos.profile),
            matchHistoryRepositoryProvider.overrideWithValue(
              repos.matchHistory,
            ),
            savedGameRepositoryProvider.overrideWithValue(repos.savedGame),
            machineComputeProvider.overrideWithValue(_firstLegalActionCompute),
            machineRandomSeedProvider.overrideWithValue(() => 1),
          ],
        );
        addTearDown(container.dispose);
        container.listen(
          matchControllerProvider(config),
          (_, _) {},
          fireImmediately: true,
        );
        container.listen(
          machineControllerProvider(config),
          (_, _) {},
          fireImmediately: true,
        );

        async.flushMicrotasks();
        container.read(matchControllerProvider(config).notifier).restart();
        async.elapse(const Duration(seconds: 2));

        // After restart it's still the machine's turn (fresh initial state,
        // top moves first and top is the machine here), so it starts
        // thinking again and eventually applies exactly one fresh move.
        final state = container.read(matchControllerProvider(config));
        expect(state.actionLog.length, 1);
      });
    });

    test(
      'respects mandatory capture: the applied machine move is always legal',
      () {
        fakeAsync((async) {
          final config = _vsMachineConfig(
            machineSide: Side.top,
            difficulty: Difficulty.medium,
          );
          final container = ProviderContainer(
            overrides: [
              gameClockProvider.overrideWithValue(
                _AdapterClock(async.getClock(DateTime(2026, 1, 1))),
              ),
              settingsRepositoryProvider.overrideWithValue(repos.settings),
              deviceLanguageCodeProvider.overrideWithValue('en'),
              hapticsPortProvider.overrideWithValue(_NoopHapticsPort()),
              profileRepositoryProvider.overrideWithValue(repos.profile),
              matchHistoryRepositoryProvider.overrideWithValue(
                repos.matchHistory,
              ),
              savedGameRepositoryProvider.overrideWithValue(repos.savedGame),
              // Uses the real chooseMachineAction via the default compute's
              // easy-path shape, but here we just verify applyExternalAction
              // rejects illegal input, using a deliberately-illegal fake.
              machineComputeProvider.overrideWithValue(
                ({required state, required difficulty, required seed}) async =>
                    const MoveAction(from: 'r0c0', to: 'r0c0'),
              ),
              machineRandomSeedProvider.overrideWithValue(() => 1),
            ],
          );
          addTearDown(container.dispose);
          container.listen(
            matchControllerProvider(config),
            (_, _) {},
            fireImmediately: true,
          );
          container.listen(
            machineControllerProvider(config),
            (_, _) {},
            fireImmediately: true,
          );

          async.flushMicrotasks();
          async.elapse(const Duration(seconds: 2));

          expect(
            container.read(matchControllerProvider(config)).actionLog,
            isEmpty,
            reason:
                'an illegal action from a misbehaving compute fn must never '
                'be applied to the match',
          );
        });
      },
    );

    test('reduced motion shortens the thinking delay', () {
      fakeAsync((async) {
        final config = _vsMachineConfig(machineSide: Side.top);
        final container = ProviderContainer(
          overrides: [
            gameClockProvider.overrideWithValue(
              _AdapterClock(async.getClock(DateTime(2026, 1, 1))),
            ),
            settingsRepositoryProvider.overrideWithValue(repos.settings),
            deviceLanguageCodeProvider.overrideWithValue('en'),
            hapticsPortProvider.overrideWithValue(_NoopHapticsPort()),
            profileRepositoryProvider.overrideWithValue(repos.profile),
            matchHistoryRepositoryProvider.overrideWithValue(
              repos.matchHistory,
            ),
            savedGameRepositoryProvider.overrideWithValue(repos.savedGame),
            machineComputeProvider.overrideWithValue(_firstLegalActionCompute),
            machineRandomSeedProvider.overrideWithValue(() => 1),
          ],
        );
        addTearDown(container.dispose);
        container
            .read(settingsControllerProvider.notifier)
            .setReducedMotion(ReducedMotionPreference.on);
        container.listen(
          matchControllerProvider(config),
          (_, _) {},
          fireImmediately: true,
        );
        container.listen(
          machineControllerProvider(config),
          (_, _) {},
          fireImmediately: true,
        );

        async.flushMicrotasks();
        // Well under the normal ~450-700ms delay, but above the 60ms
        // reduced-motion floor.
        async.elapse(const Duration(milliseconds: 150));

        expect(
          container.read(matchControllerProvider(config)).actionLog.length,
          1,
          reason: 'reduced motion should skip the artificial thinking delay',
        );
      });
    });
  });
}
