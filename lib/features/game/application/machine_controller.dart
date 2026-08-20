import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../game/ai/difficulty.dart';
import '../../../game/ai/machine_player.dart';
import '../../../game/engine/game_action.dart';
import '../../../game/engine/game_state.dart';
import 'game_clock.dart';
import 'match_config.dart';
import 'match_controller.dart';
import 'move_presentation_controller.dart';

/// 07-android-quality-security-and-release.md calls for AI search node/time
/// budgets to be bounded per device quality, not just per difficulty. This
/// app has no real device-capability probe, so [VisualQuality] (already a
/// user-facing proxy for "how much this device/session can spend on visual
/// effects," per 04-ui-ux-and-visual-system.md) doubles as that signal: Low
/// gets a shorter [Difficulty.difficult] search budget so a weak device
/// stays responsive, Standard/Auto/High keep the existing default.
Duration difficultTimeBudgetFor(VisualQuality quality) =>
    quality == VisualQuality.low
    ? const Duration(milliseconds: 500)
    : defaultDifficultTimeBudget;

/// Seed source for the machine's [Random] instances. Overridden in tests for
/// deterministic behavior; production draws fresh entropy per move.
final machineRandomSeedProvider = Provider<int Function()>((ref) {
  final entropy = Random();
  return () => entropy.nextInt(1 << 31);
});

typedef MachineComputeFn = Future<GameAction> Function({
  required GameState state,
  required Difficulty difficulty,
  required int seed,
  required Duration difficultTimeBudget,
});

/// Runs the actual search. Medium/Difficult go through [Isolate.run] so the
/// (bounded, but non-trivial) search never blocks the UI isolate; Easy is
/// cheap enough to resolve immediately. Overridden in tests with a fast
/// synchronous-future fake so controller-level tests don't pay real isolate
/// spawn/timing costs — the search algorithm itself is covered separately
/// in `test/game/ai`.
final machineComputeProvider = Provider<MachineComputeFn>(
  (ref) => _defaultCompute,
);

Future<GameAction> _defaultCompute({
  required GameState state,
  required Difficulty difficulty,
  required int seed,
  required Duration difficultTimeBudget,
}) {
  if (difficulty == Difficulty.easy) {
    return Future.value(
      chooseMachineAction(
        state: state,
        difficulty: difficulty,
        random: Random(seed),
      ),
    );
  }
  return Isolate.run(
    () => chooseMachineAction(
      state: state,
      difficulty: difficulty,
      random: Random(seed),
      difficultTimeBudget: difficultTimeBudget,
    ),
  );
}

class MachineControllerState {
  final bool isThinking;
  const MachineControllerState({required this.isThinking});
  static const idle = MachineControllerState(isThinking: false);
}

/// Drives the offline machine opponent for a vs-Machine [MatchConfig].
/// Whenever it becomes the machine's turn, shows a bounded/cancellable
/// "thinking" state, computes a move via the pure [chooseMachineAction]
/// (never bypassing the engine — the AI sees only the same [GameState] and
/// `legalActions` a human would), and applies it through
/// [MatchController.applyExternalAction], which feeds the exact same
/// [MovePresentationController] timeline used for human moves.
///
/// Cancellation (pause/restart/resign/any match-state change) is handled by
/// a monotonic generation counter: an in-flight delay or search result is
/// simply discarded if the generation has moved on by the time it resolves,
/// rather than needing true isolate preemption.
class MachineController extends Notifier<MachineControllerState> {
  MachineController(this.config);

  final MatchConfig config;
  int _generation = 0;

  static const _minThinkingDelay = Duration(milliseconds: 450);
  static const _maxThinkingDelayJitter = Duration(milliseconds: 250);
  static const _reducedMotionThinkingDelay = Duration(milliseconds: 60);

  GameClock get _clock => ref.read(gameClockProvider);

  @override
  MachineControllerState build() {
    ref.onDispose(() => _generation++);
    if (config.isVsMachine) {
      ref.listen(matchControllerProvider(config), _onMatchStateChanged);
      // Defer the "is it already the machine's turn at match start" check
      // until after this build() call returns — state isn't settable yet.
      Future.microtask(() {
        if (ref.exists(matchControllerProvider(config))) {
          _onMatchStateChanged(null, ref.read(matchControllerProvider(config)));
        }
      });
    }
    return MachineControllerState.idle;
  }

  void _onMatchStateChanged(MatchUiState? previous, MatchUiState next) {
    final shouldBeThinkingNow =
        config.isVsMachine &&
        !next.isPaused &&
        next.gameState.phase == GamePhase.playing &&
        next.gameState.turn == config.machineSide;

    // Any match-state change (a human move, pause, resume, restart, resign,
    // or the machine's own just-applied move) invalidates whatever delay or
    // search was previously in flight.
    _generation++;
    if (state.isThinking) state = MachineControllerState.idle;

    if (shouldBeThinkingNow) {
      _startThinking(next);
    }
  }

  void _startThinking(MatchUiState matchStateAtStart) {
    final myGeneration = _generation;
    state = const MachineControllerState(isThinking: true);

    final settings = ref.read(settingsControllerProvider);
    final reduced = resolveReducedMotion(settings.reducedMotion);
    final seed = ref.read(machineRandomSeedProvider)();
    final minDelay = reduced
        ? _reducedMotionThinkingDelay
        : _minThinkingDelay +
              Duration(
                milliseconds: seed % _maxThinkingDelayJitter.inMilliseconds,
              );
    final startedAt = _clock.now();

    ref
        .read(machineComputeProvider)(
          state: matchStateAtStart.gameState,
          difficulty: config.difficulty,
          seed: seed,
          difficultTimeBudget: difficultTimeBudgetFor(settings.visualQuality),
        )
        .then((action) async {
          if (myGeneration != _generation) {
            return; // stale: superseded meanwhile
          }

          final elapsed = _clock.now().difference(startedAt);
          final remaining = minDelay - elapsed;
          if (remaining > Duration.zero) {
            await Future<void>.delayed(remaining);
          }
          if (myGeneration != _generation) {
            return; // could go stale during the wait too
          }

          state = MachineControllerState.idle;
          ref
              .read(matchControllerProvider(config).notifier)
              .applyExternalAction(action);
        });
  }
}

final machineControllerProvider = NotifierProvider.family
    .autoDispose<MachineController, MachineControllerState, MatchConfig>(
      MachineController.new,
    );
