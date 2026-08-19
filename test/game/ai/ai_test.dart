import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_beads/game/ai/difficulty.dart';
import 'package:twelve_beads/game/ai/machine_player.dart';
import 'package:twelve_beads/game/ai/search.dart';
import 'package:twelve_beads/game/board/board_graph.dart';
import 'package:twelve_beads/game/engine/game_action.dart';
import 'package:twelve_beads/game/engine/game_state.dart';
import 'package:twelve_beads/game/engine/rules_engine.dart';
import 'package:twelve_beads/game/engine/ruleset.dart';
import 'package:twelve_beads/game/engine/side.dart';

const _optionalCaptureRuleset = Ruleset(
  id: 'test_optional_capture',
  version: 1,
  displayName: 'Test (optional capture)',
  mandatoryCapture: false,
  chainCaptureMandatory: true,
  noCaptureMoveLimitForDraw: 40,
  stalemateIsLossForPlayerToMove: true,
);

GameState _customState({
  required Map<NodeId, Side> pieces,
  required Side turn,
  Ruleset ruleset = Ruleset.classicAlquerque,
}) {
  return GameState(
    graph: BoardGraph.standard(),
    pieces: Map.unmodifiable(pieces),
    turn: turn,
    ruleset: ruleset,
    phase: GamePhase.playing,
    winner: null,
    winReason: null,
    isDraw: false,
    mustContinueCaptureFrom: null,
    chainStepIndex: 0,
    plyCount: 0,
    pliesSinceLastCapture: 0,
  );
}

void main() {
  group('chooseMachineAction legality (all difficulties)', () {
    for (final difficulty in Difficulty.values) {
      test(
        '$difficulty always returns a legal action at the initial position',
        () {
          final state = GameState.initial();
          final action = chooseMachineAction(
            state: state,
            difficulty: difficulty,
            random: Random(1),
            difficultTimeBudget: const Duration(milliseconds: 150),
          );
          expect(legalActions(state), contains(action));
        },
      );

      test(
        '$difficulty respects mandatory capture on a forced-capture position',
        () {
          final state = _customState(
            pieces: {
              'r2c0': Side.top,
              'r2c1': Side.bottom,
              'r4c4': Side.top,
              'r0c0': Side.bottom,
            },
            turn: Side.top,
          );
          final legal = legalActions(state);
          expect(legal, everyElement(isA<CaptureAction>()));

          final action = chooseMachineAction(
            state: state,
            difficulty: difficulty,
            random: Random(2),
            difficultTimeBudget: const Duration(milliseconds: 150),
          );
          expect(action, isA<CaptureAction>());
          expect(legal, contains(action));
        },
      );
    }
  });

  test('Easy is deterministic for a given seed', () {
    final state = GameState.initial();
    final first = chooseMachineAction(
      state: state,
      difficulty: Difficulty.easy,
      random: Random(7),
    );
    final second = chooseMachineAction(
      state: state,
      difficulty: Difficulty.easy,
      random: Random(7),
    );
    expect(first, second);
  });

  test('Medium and Difficult prefer an available capture over a neutral move '
      'even when capturing is optional', () {
    // Optional-capture ruleset: top can either capture (clearly good,
    // gains material) or make an unrelated neutral move elsewhere.
    final state = _customState(
      pieces: {'r2c0': Side.top, 'r2c1': Side.bottom, 'r4c4': Side.top},
      turn: Side.top,
      ruleset: _optionalCaptureRuleset,
    );

    for (final difficulty in [Difficulty.medium, Difficulty.difficult]) {
      final action = chooseMachineAction(
        state: state,
        difficulty: difficulty,
        random: Random(3),
        difficultTimeBudget: const Duration(milliseconds: 200),
      );
      expect(
        action,
        const CaptureAction(from: 'r2c0', over: 'r2c1', to: 'r2c2'),
        reason: '$difficulty should recognize the free material gain',
      );
    }
  });

  group('search internals', () {
    test(
      'negamaxSearch on a forced double-capture chain returns the first jump',
      () {
        final state = _customState(
          pieces: {
            'r0c0': Side.top,
            'r0c1': Side.bottom,
            'r0c3': Side.bottom,
            'r4c4': Side.bottom,
          },
          turn: Side.top,
        );
        final result = negamaxSearch(state, 4);
        expect(
          result.action,
          const CaptureAction(from: 'r0c0', over: 'r0c1', to: 'r0c2'),
        );
      },
    );

    test(
      'iterativeDeepeningSearch never returns an illegal action and completes '
      'within a tight time budget',
      () {
        final state = GameState.initial();
        final stopwatch = Stopwatch()..start();
        final result = iterativeDeepeningSearch(
          state,
          timeBudget: const Duration(milliseconds: 100),
          clockNow: DateTime.now,
        );
        stopwatch.stop();

        expect(legalActions(state), contains(result.action));
        expect(
          stopwatch.elapsed,
          lessThan(const Duration(seconds: 3)),
          reason: 'must stay responsive under a tight time budget, not hang',
        );
      },
    );

    test('iterativeDeepeningSearch falls back to a legal action even with an '
        'already-expired budget', () {
      final state = GameState.initial();
      final result = iterativeDeepeningSearch(
        state,
        timeBudget: Duration.zero,
        clockNow: DateTime.now,
      );
      expect(legalActions(state), contains(result.action));
    });

    test('orderedActions places captures before non-captures', () {
      const actions = <GameAction>[
        MoveAction(from: 'r1c1', to: 'r2c2'),
        CaptureAction(from: 'r0c0', over: 'r0c1', to: 'r0c2'),
        MoveAction(from: 'r3c3', to: 'r3c4'),
      ];
      final ordered = orderedActions(actions);
      expect(ordered.first, isA<CaptureAction>());
    });
  });
}
