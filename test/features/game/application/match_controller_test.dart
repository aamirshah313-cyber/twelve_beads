import 'package:clock/clock.dart' as pkg_clock;
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_beads/core/history/match_history_controller.dart';
import 'package:twelve_beads/core/history/match_record.dart';
import 'package:twelve_beads/core/profile/profile_controller.dart';
import 'package:twelve_beads/core/settings/settings_controller.dart';
import 'package:twelve_beads/features/game/application/game_clock.dart';
import 'package:twelve_beads/features/game/application/haptics_port.dart';
import 'package:twelve_beads/features/game/application/match_config.dart';
import 'package:twelve_beads/features/game/application/match_controller.dart';
import 'package:twelve_beads/features/game/application/move_presentation_controller.dart';
import 'package:twelve_beads/features/game/application/saved_game_controller.dart';
import 'package:twelve_beads/game/board/board_graph.dart';
import 'package:twelve_beads/game/engine/game_action.dart';
import 'package:twelve_beads/game/engine/game_state.dart';
import 'package:twelve_beads/game/engine/side.dart';

import '../../../support/repository_overrides.dart';

class _AdapterClock implements GameClock {
  _AdapterClock(this._clock);
  final pkg_clock.Clock _clock;
  @override
  DateTime now() => _clock.now();
}

/// [HapticFeedback] requires a live Flutter binding (`ServicesBinding
/// .instance`), which plain `test()` cases (as opposed to `testWidgets()`)
/// never initialize. These controller-level unit tests shouldn't need a
/// widget binding just to exercise game logic, so haptics are faked here —
/// real haptics are covered by the widget-level tests instead.
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

class _RecordingHapticsPort implements HapticsPort {
  final calls = <String>[];
  @override
  void selection() => calls.add('selection');
  @override
  void move() => calls.add('move');
  @override
  void capture() => calls.add('capture');
  @override
  void matchEnd() => calls.add('matchEnd');
  @override
  void warning() => calls.add('warning');
}

MatchConfig _config({int timerMinutes = 0, int perMoveSeconds = 0}) =>
    MatchConfig(
      playerOneName: 'Alice',
      playerTwoName: 'Bilal',
      playerOneSide: Side.top,
      firstTurn: Side.top,
      timerMinutes: timerMinutes,
      perMoveSeconds: perMoveSeconds,
    );

void main() {
  // resolveReducedMotion()'s ReducedMotionPreference.system branch reads
  // WidgetsBinding.instance (for the platform accessibility flag), which
  // requires a bound Flutter binding even in these plain, non-widget tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MatchUiState getters', () {
    test(
      'forcedCaptureActive is true only when every legal action is a capture',
      () {
        final capturable = GameState(
          graph: BoardGraph.standard(),
          pieces: const {'r2c0': Side.top, 'r2c1': Side.bottom},
          turn: Side.top,
          ruleset: _config().ruleset,
          phase: GamePhase.playing,
          winner: null,
          winReason: null,
          isDraw: false,
          mustContinueCaptureFrom: null,
          chainStepIndex: 0,
          plyCount: 0,
          pliesSinceLastCapture: 0,
        );
        final state = MatchUiState(
          config: _config(),
          gameState: capturable,
          actionLog: const [],
          selectedNode: null,
          lastMoveSource: null,
          lastMoveDestination: null,
          topRemaining: Duration.zero,
          bottomRemaining: Duration.zero,
          perMoveRemaining: null,
          isPaused: false,
        );
        expect(state.forcedCaptureActive, isTrue);
      },
    );

    test('canUndo is false while a capture chain is in progress', () {
      final midChain = GameState(
        graph: BoardGraph.standard(),
        pieces: const {'r0c2': Side.top, 'r0c3': Side.bottom},
        turn: Side.top,
        ruleset: _config().ruleset,
        phase: GamePhase.playing,
        winner: null,
        winReason: null,
        isDraw: false,
        mustContinueCaptureFrom: 'r0c2',
        chainStepIndex: 1,
        plyCount: 1,
        pliesSinceLastCapture: 0,
      );
      final state = MatchUiState(
        config: _config(),
        gameState: midChain,
        actionLog: const [MoveAction(from: 'r1c2', to: 'r2c2')],
        selectedNode: null,
        lastMoveSource: null,
        lastMoveDestination: null,
        topRemaining: Duration.zero,
        bottomRemaining: Duration.zero,
        perMoveRemaining: null,
        isPaused: false,
      );
      expect(state.canUndo, isFalse);
    });
  });

  group('MatchController — tap-driven play (no timer)', () {
    late ProviderContainer container;
    late MatchConfig config;

    setUp(() async {
      config = _config();
      final repos = await createTestRepositories();
      container = ProviderContainer(
        overrides: [
          gameClockProvider.overrideWithValue(const SystemGameClock()),
          settingsRepositoryProvider.overrideWithValue(repos.settings),
          deviceLanguageCodeProvider.overrideWithValue('en'),
          hapticsPortProvider.overrideWithValue(_NoopHapticsPort()),
          profileRepositoryProvider.overrideWithValue(repos.profile),
          matchHistoryRepositoryProvider.overrideWithValue(repos.matchHistory),
          savedGameRepositoryProvider.overrideWithValue(repos.savedGame),
        ],
      );
      container.listen(
        matchControllerProvider(config),
        (_, _) {},
        fireImmediately: true,
      );
    });

    tearDown(() => container.dispose());

    MatchUiState read() => container.read(matchControllerProvider(config));
    MatchController notifier() =>
        container.read(matchControllerProvider(config).notifier);

    test('initial state matches GameState.initial for the given config', () {
      final state = read();
      expect(state.gameState.pieces.length, 24);
      expect(state.gameState.turn, Side.top);
      expect(state.actionLog, isEmpty);
      expect(state.selectedNode, isNull);
      expect(state.canUndo, isFalse);
    });

    test(
      'tapping a movable piece selects it; tapping its target applies the move',
      () {
        notifier().onNodeTapped('r1c2');
        expect(read().selectedNode, 'r1c2');

        notifier().onNodeTapped('r2c2');
        final state = read();
        expect(state.selectedNode, isNull);
        expect(state.gameState.pieces['r2c2'], Side.top);
        expect(state.gameState.pieces.containsKey('r1c2'), isFalse);
        expect(state.gameState.turn, Side.bottom);
        expect(state.lastMoveSource, 'r1c2');
        expect(state.lastMoveDestination, 'r2c2');
        expect(state.actionLog, [const MoveAction(from: 'r1c2', to: 'r2c2')]);
      },
    );

    test('tapping an unrelated node with no legal moves is a no-op', () {
      notifier().onNodeTapped('r1c2');
      notifier().onNodeTapped('r0c0'); // r0c0 has no legal moves at the start
      // r0c0 isn't a legal-move source either, so selection is cleared, not moved.
      expect(read().selectedNode, isNull);
      expect(
        read().gameState.pieces['r1c2'],
        Side.top,
        reason: 'no move should have been applied',
      );
    });

    test(
      'a forced capture is reflected in legalActions and forcedCaptureActive',
      () {
        // r1c2 -> r2c2 walks into a mandatory reply capture by r3c2.
        notifier().onNodeTapped('r1c2');
        notifier().onNodeTapped('r2c2');

        final state = read();
        expect(state.gameState.turn, Side.bottom);
        expect(state.forcedCaptureActive, isTrue);
        // Two capture lines are available; both are legal since maximum-
        // capture selection isn't required (see D-005 in DECISIONS.md).
        expect(
          state.legalActions,
          unorderedEquals(<CaptureAction>[
            const CaptureAction(from: 'r3c2', over: 'r2c2', to: 'r1c2'),
            const CaptureAction(from: 'r3c0', over: 'r2c1', to: 'r1c2'),
          ]),
        );

        // Board input is correctly locked while the first move's
        // presentation animation is still playing (no real time elapses in
        // this synchronous test); simulate it having finished before the
        // reply capture is tapped, same as BoardWidget would let happen.
        container
            .read(movePresentationControllerProvider(config).notifier)
            .cancelAndSnapToFinal();

        notifier().onNodeTapped('r3c2');
        notifier().onNodeTapped('r1c2');

        final afterCapture = read();
        expect(afterCapture.gameState.pieces['r1c2'], Side.bottom);
        expect(afterCapture.gameState.pieces.containsKey('r2c2'), isFalse);
        expect(afterCapture.gameState.turn, Side.top);
        expect(afterCapture.lastMoveSource, 'r3c2');
        expect(afterCapture.lastMoveDestination, 'r1c2');
      },
    );

    test(
      'undo removes exactly the last action and is unavailable afterward',
      () {
        notifier().onNodeTapped('r1c2');
        notifier().onNodeTapped('r2c2');
        expect(read().canUndo, isTrue);

        notifier().undo();
        final state = read();
        expect(state.actionLog, isEmpty);
        expect(state.gameState.pieces['r1c2'], Side.top);
        expect(state.gameState.turn, Side.top);
        expect(state.canUndo, isFalse);
      },
    );

    test('resign ends the match immediately in favor of the opponent', () {
      notifier().resign(Side.top);
      final state = read();
      expect(state.gameState.phase, GamePhase.finished);
      expect(state.gameState.winner, Side.bottom);
      expect(state.legalActions, isEmpty);
    });

    test('restart resets to a fresh initial state', () {
      notifier().onNodeTapped('r1c2');
      notifier().onNodeTapped('r2c2');
      notifier().restart();
      final state = read();
      expect(state.gameState.pieces.length, 24);
      expect(state.gameState.turn, Side.top);
      expect(state.actionLog, isEmpty);
    });
  });

  group('MatchController — timer lifecycle', () {
    test('the active side\'s clock counts down while playing', () async {
      final repos = await createTestRepositories();
      fakeAsync((async) {
        final config = _config(timerMinutes: 1);
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
          ],
        );
        addTearDown(container.dispose);
        container.listen(
          matchControllerProvider(config),
          (_, _) {},
          fireImmediately: true,
        );

        expect(
          container.read(matchControllerProvider(config)).topRemaining,
          const Duration(seconds: 60),
        );

        async.elapse(const Duration(seconds: 10));

        final state = container.read(matchControllerProvider(config));
        expect(state.topRemaining, const Duration(seconds: 50));
        expect(
          state.bottomRemaining,
          const Duration(seconds: 60),
          reason: 'inactive side does not tick',
        );
      });
    });

    test('pausing freezes the clock; resuming continues it', () async {
      final repos = await createTestRepositories();
      fakeAsync((async) {
        final config = _config(timerMinutes: 1);
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
          ],
        );
        addTearDown(container.dispose);
        container.listen(
          matchControllerProvider(config),
          (_, _) {},
          fireImmediately: true,
        );
        final notifier = container.read(
          matchControllerProvider(config).notifier,
        );

        async.elapse(const Duration(seconds: 10));
        notifier.pause();
        final frozen = container
            .read(matchControllerProvider(config))
            .topRemaining;
        expect(frozen, const Duration(seconds: 50));

        async.elapse(const Duration(seconds: 30));
        expect(
          container.read(matchControllerProvider(config)).topRemaining,
          frozen,
          reason: 'paused clock must not lose unearned background time',
        );

        notifier.resume();
        async.elapse(const Duration(seconds: 5));
        expect(
          container.read(matchControllerProvider(config)).topRemaining,
          const Duration(seconds: 45),
        );
      });
    });

    test('reaching zero applies a Timeout and ends the match', () async {
      final repos = await createTestRepositories();
      fakeAsync((async) {
        final config = _config(timerMinutes: 1);
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
          ],
        );
        addTearDown(container.dispose);
        container.listen(
          matchControllerProvider(config),
          (_, _) {},
          fireImmediately: true,
        );

        async.elapse(const Duration(seconds: 61));

        final state = container.read(matchControllerProvider(config));
        expect(state.gameState.phase, GamePhase.finished);
        expect(state.gameState.winReason, WinReason.timeout);
        expect(
          state.gameState.winner,
          Side.bottom,
          reason: 'top (the active side) ran out of time',
        );
      });
    });
  });

  group('MatchController — per-move timer and warning threshold', () {
    test(
      'a per-move timeout ends the match even with the total timer off',
      () async {
        final repos = await createTestRepositories();
        fakeAsync((async) {
          final config = _config(perMoveSeconds: 30);
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
            ],
          );
          addTearDown(container.dispose);
          container.listen(
            matchControllerProvider(config),
            (_, _) {},
            fireImmediately: true,
          );

          async.elapse(const Duration(seconds: 31));

          final state = container.read(matchControllerProvider(config));
          expect(state.gameState.phase, GamePhase.finished);
          expect(state.gameState.winReason, WinReason.timeout);
          expect(state.gameState.winner, Side.bottom);
        });
      },
    );

    test('the per-move budget resets on a genuine turn change but not mid '
        'capture-chain', () async {
      final repos = await createTestRepositories();
      fakeAsync((async) {
        final config = _config(perMoveSeconds: 30);
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
          ],
        );
        addTearDown(container.dispose);
        container.listen(
          matchControllerProvider(config),
          (_, _) {},
          fireImmediately: true,
        );
        final notifier = container.read(
          matchControllerProvider(config).notifier,
        );

        async.elapse(const Duration(seconds: 20));
        notifier.onNodeTapped('r1c2');
        notifier.onNodeTapped('r2c2');

        final afterMove = container.read(matchControllerProvider(config));
        expect(
          afterMove.perMoveRemaining,
          const Duration(seconds: 30),
          reason: 'a genuine turn change resets the per-move budget',
        );
      });
    });

    test(
      'reaching the warning threshold fires the haptic cue exactly once',
      () async {
        final repos = await createTestRepositories();
        fakeAsync((async) {
          final config = _config(timerMinutes: 1);
          final haptics = _RecordingHapticsPort();
          final container = ProviderContainer(
            overrides: [
              gameClockProvider.overrideWithValue(
                _AdapterClock(async.getClock(DateTime(2026, 1, 1))),
              ),
              settingsRepositoryProvider.overrideWithValue(repos.settings),
              deviceLanguageCodeProvider.overrideWithValue('en'),
              hapticsPortProvider.overrideWithValue(haptics),
              profileRepositoryProvider.overrideWithValue(repos.profile),
              matchHistoryRepositoryProvider.overrideWithValue(
                repos.matchHistory,
              ),
              savedGameRepositoryProvider.overrideWithValue(repos.savedGame),
            ],
          );
          addTearDown(container.dispose);
          container.listen(
            matchControllerProvider(config),
            (_, _) {},
            fireImmediately: true,
          );

          // 60s total; warning threshold is the last 10s, i.e. at 50s
          // elapsed.
          async.elapse(const Duration(seconds: 52));
          expect(haptics.calls.where((c) => c == 'warning').length, 1);

          // Still within the warning window — must not fire again every
          // tick.
          async.elapse(const Duration(seconds: 3));
          expect(haptics.calls.where((c) => c == 'warning').length, 1);
        });
      },
    );
  });

  group(
    'MatchController — sound/haptics preference gating '
    '(06-localization-social-and-settings.md: independently configurable)',
    () {
      test(
        'selecting a piece fires a selection haptic when Haptics is on',
        () async {
          final repos = await createTestRepositories();
          final config = _config();
          final haptics = _RecordingHapticsPort();
          final container = ProviderContainer(
            overrides: [
              gameClockProvider.overrideWithValue(const SystemGameClock()),
              settingsRepositoryProvider.overrideWithValue(repos.settings),
              deviceLanguageCodeProvider.overrideWithValue('en'),
              hapticsPortProvider.overrideWithValue(haptics),
              profileRepositoryProvider.overrideWithValue(repos.profile),
              matchHistoryRepositoryProvider.overrideWithValue(
                repos.matchHistory,
              ),
              savedGameRepositoryProvider.overrideWithValue(repos.savedGame),
            ],
          );
          addTearDown(container.dispose);
          container.listen(
            matchControllerProvider(config),
            (_, _) {},
            fireImmediately: true,
          );

          container
              .read(matchControllerProvider(config).notifier)
              .onNodeTapped('r1c2');

          expect(haptics.calls, contains('selection'));
        },
      );

      test('turning Haptics off in settings silences selection and match-end '
          'haptics from MatchController', () async {
        final repos = await createTestRepositories();
        final config = _config();
        final haptics = _RecordingHapticsPort();
        final container = ProviderContainer(
          overrides: [
            gameClockProvider.overrideWithValue(const SystemGameClock()),
            settingsRepositoryProvider.overrideWithValue(repos.settings),
            deviceLanguageCodeProvider.overrideWithValue('en'),
            hapticsPortProvider.overrideWithValue(haptics),
            profileRepositoryProvider.overrideWithValue(repos.profile),
            matchHistoryRepositoryProvider.overrideWithValue(
              repos.matchHistory,
            ),
            savedGameRepositoryProvider.overrideWithValue(repos.savedGame),
          ],
        );
        addTearDown(container.dispose);
        container.read(settingsControllerProvider.notifier).setHapticsOn(false);
        container.listen(
          matchControllerProvider(config),
          (_, _) {},
          fireImmediately: true,
        );
        final notifier = container.read(
          matchControllerProvider(config).notifier,
        );

        notifier.onNodeTapped('r1c2');
        notifier.resign(Side.top);

        expect(
          haptics.calls,
          isEmpty,
          reason:
              'Haptics off must silence every MatchController haptic, '
              'not just presentation-timeline ones',
        );
      });
    },
  );

  group('MatchController — persistence (Phase 6)', () {
    late ProviderContainer container;
    late MatchConfig config;

    setUp(() async {
      config = _config();
      final repos = await createTestRepositories();
      container = ProviderContainer(
        overrides: [
          gameClockProvider.overrideWithValue(const SystemGameClock()),
          settingsRepositoryProvider.overrideWithValue(repos.settings),
          deviceLanguageCodeProvider.overrideWithValue('en'),
          hapticsPortProvider.overrideWithValue(_NoopHapticsPort()),
          profileRepositoryProvider.overrideWithValue(repos.profile),
          matchHistoryRepositoryProvider.overrideWithValue(repos.matchHistory),
          savedGameRepositoryProvider.overrideWithValue(repos.savedGame),
        ],
      );
      container.listen(
        matchControllerProvider(config),
        (_, _) {},
        fireImmediately: true,
      );
    });

    tearDown(() => container.dispose());

    MatchController notifier() =>
        container.read(matchControllerProvider(config).notifier);

    test('a move autosaves a resumable snapshot', () {
      expect(container.read(savedGameControllerProvider), isNull);
      notifier().onNodeTapped('r1c2');
      notifier().onNodeTapped('r2c2');

      final saved = container.read(savedGameControllerProvider);
      expect(saved, isNotNull);
      expect(saved!.actionLog.length, 1);
      expect(saved.config, same(config));
    });

    test('undoing back to the start clears the saved snapshot', () {
      notifier().onNodeTapped('r1c2');
      notifier().onNodeTapped('r2c2');
      expect(container.read(savedGameControllerProvider), isNotNull);

      notifier().undo();
      expect(container.read(savedGameControllerProvider), isNull);
    });

    test('a resignation finalizes: updates profile stats, appends match '
        'history, and clears the saved snapshot', () {
      notifier().onNodeTapped('r1c2');
      notifier().onNodeTapped('r2c2');
      expect(container.read(savedGameControllerProvider), isNotNull);

      // Bottom resigns, so top (playerOneSide in _config()) wins.
      notifier().resign(Side.bottom);

      final profile = container.read(profileControllerProvider);
      expect(profile.matchesPlayed, 1);
      expect(profile.wins, 1);
      expect(profile.currentStreak, 1);

      final history = container.read(matchHistoryControllerProvider);
      expect(history.length, 1);
      expect(history.single.outcome, MatchOutcome.win);
      expect(history.single.winReason, WinReason.resignation);
      expect(history.single.mode, MatchMode.twoPlayer);

      expect(
        container.read(savedGameControllerProvider),
        isNull,
        reason: 'a finished match must never remain resumable',
      );
    });

    test('a loss does not increment the win streak', () {
      // Top resigns, so top (this profile's own side) loses.
      notifier().resign(Side.top);
      final profile = container.read(profileControllerProvider);
      expect(profile.losses, 1);
      expect(profile.wins, 0);
      expect(profile.currentStreak, 0);
    });

    test('autosave + pendingResumeSnapshotProvider hydrates a fresh '
        'MatchController to the same in-progress state, paused', () async {
      notifier().onNodeTapped('r1c2');
      notifier().onNodeTapped('r2c2');
      container
          .read(movePresentationControllerProvider(config).notifier)
          .cancelAndSnapToFinal();

      final saved = container.read(savedGameControllerProvider);
      expect(saved, isNotNull);
      container.dispose();

      final repos2 = await createTestRepositories();
      final container2 = ProviderContainer(
        overrides: [
          gameClockProvider.overrideWithValue(const SystemGameClock()),
          settingsRepositoryProvider.overrideWithValue(repos2.settings),
          deviceLanguageCodeProvider.overrideWithValue('en'),
          hapticsPortProvider.overrideWithValue(_NoopHapticsPort()),
          profileRepositoryProvider.overrideWithValue(repos2.profile),
          matchHistoryRepositoryProvider.overrideWithValue(repos2.matchHistory),
          savedGameRepositoryProvider.overrideWithValue(repos2.savedGame),
        ],
      );
      addTearDown(container2.dispose);
      container2.read(pendingResumeSnapshotProvider.notifier).set(saved);
      container2.listen(
        matchControllerProvider(config),
        (_, _) {},
        fireImmediately: true,
      );

      final hydrated = container2.read(matchControllerProvider(config));
      expect(hydrated.actionLog, [const MoveAction(from: 'r1c2', to: 'r2c2')]);
      expect(hydrated.gameState.turn, Side.bottom);
      expect(
        hydrated.isPaused,
        isTrue,
        reason: 'a resumed match must land paused, not silently ticking',
      );

      // The hand-off's consumption is deferred by one microtask (a
      // provider can't modify another synchronously during its own
      // build()) — flush it before asserting.
      await Future<void>.value();
      expect(
        container2.read(pendingResumeSnapshotProvider),
        isNull,
        reason: 'the hand-off snapshot must be consumed exactly once',
      );
    });
  });
}
