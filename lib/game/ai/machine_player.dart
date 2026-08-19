import 'dart:math';

import '../engine/game_action.dart';
import '../engine/game_state.dart';
import '../engine/rules_engine.dart';
import 'difficulty.dart';
import 'search.dart';

/// Depth for [Difficulty.medium]'s fixed-depth search. Kept shallow per the
/// difficulty contract in 05-ai-and-gameplay-systems.md.
const mediumSearchDepth = 3;

/// Default device-safe time budget for [Difficulty.difficult].
const defaultDifficultTimeBudget = Duration(milliseconds: 1200);

/// Pure function: chooses the machine's next action for [state]. This is
/// the entire AI surface — it receives only the same immutable [GameState]
/// and [legalActions] a human player would see, and never mutates state or
/// bypasses the engine. Safe to run in a background isolate (no Flutter
/// dependencies, no closures over unsendable objects other than the
/// optional [clockNow] callback).
///
/// [random] must be seeded by the caller for deterministic, testable
/// behavior; production call sites pass a freshly-seeded [Random] per
/// match/move as appropriate.
GameAction chooseMachineAction({
  required GameState state,
  required Difficulty difficulty,
  required Random random,
  Duration difficultTimeBudget = defaultDifficultTimeBudget,
  DateTime Function()? clockNow,
}) {
  final legal = legalActions(state);
  if (legal.isEmpty) {
    throw StateError(
      'chooseMachineAction called with no legal actions available',
    );
  }

  return switch (difficulty) {
    Difficulty.easy => legal[random.nextInt(legal.length)],
    Difficulty.medium =>
      (negamaxSearch(state, mediumSearchDepth).action) ?? legal.first,
    Difficulty.difficult =>
      (iterativeDeepeningSearch(
            state,
            timeBudget: difficultTimeBudget,
            clockNow: clockNow ?? DateTime.now,
          ).action) ??
          legal.first,
  };
}
