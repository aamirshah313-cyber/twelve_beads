import 'package:clock/clock.dart' as pkg_clock;
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_beads/features/game/application/game_clock.dart';
import 'package:twelve_beads/features/game/application/match_config.dart';
import 'package:twelve_beads/features/game/application/match_controller.dart';
import 'package:twelve_beads/game/board/board_graph.dart';
import 'package:twelve_beads/game/engine/game_action.dart';
import 'package:twelve_beads/game/engine/game_state.dart';
import 'package:twelve_beads/game/engine/side.dart';

class _AdapterClock implements GameClock {
  _AdapterClock(this._clock);
  final pkg_clock.Clock _clock;
  @override
  DateTime now() => _clock.now();
}

MatchConfig _config({int timerMinutes = 0}) => MatchConfig(
  playerOneName: 'Alice',
  playerTwoName: 'Bilal',
  playerOneSide: Side.top,
  firstTurn: Side.top,
  timerMinutes: timerMinutes,
);

void main() {
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
        isPaused: false,
      );
      expect(state.canUndo, isFalse);
    });
  });

  group('MatchController — tap-driven play (no timer)', () {
    late ProviderContainer container;
    late MatchConfig config;

    setUp(() {
      config = _config();
      container = ProviderContainer(
        overrides: [
          gameClockProvider.overrideWithValue(const SystemGameClock()),
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
    test('the active side\'s clock counts down while playing', () {
      fakeAsync((async) {
        final config = _config(timerMinutes: 1);
        final container = ProviderContainer(
          overrides: [
            gameClockProvider.overrideWithValue(
              _AdapterClock(async.getClock(DateTime(2026, 1, 1))),
            ),
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

    test('pausing freezes the clock; resuming continues it', () {
      fakeAsync((async) {
        final config = _config(timerMinutes: 1);
        final container = ProviderContainer(
          overrides: [
            gameClockProvider.overrideWithValue(
              _AdapterClock(async.getClock(DateTime(2026, 1, 1))),
            ),
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

    test('reaching zero applies a Timeout and ends the match', () {
      fakeAsync((async) {
        final config = _config(timerMinutes: 1);
        final container = ProviderContainer(
          overrides: [
            gameClockProvider.overrideWithValue(
              _AdapterClock(async.getClock(DateTime(2026, 1, 1))),
            ),
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
}
