import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_beads/core/history/match_history_controller.dart';
import 'package:twelve_beads/core/l10n/gen/app_localizations.dart';
import 'package:twelve_beads/core/profile/profile_controller.dart';
import 'package:twelve_beads/core/settings/settings_controller.dart';
import 'package:twelve_beads/features/game/application/match_config.dart';
import 'package:twelve_beads/features/game/application/saved_game_controller.dart';
import 'package:twelve_beads/features/game/presentation/board_painter.dart';
import 'package:twelve_beads/features/game/presentation/board_widget.dart';
import 'package:twelve_beads/features/game/presentation/match_screen.dart';
import 'package:twelve_beads/game/ai/difficulty.dart';
import 'package:twelve_beads/game/board/board_graph.dart';
import 'package:twelve_beads/features/game/presentation/board_layout.dart';
import 'package:twelve_beads/game/engine/side.dart';

import '../../../support/repository_overrides.dart';

MatchConfig _config() => const MatchConfig(
  playerOneName: 'Alice',
  playerTwoName: 'Bilal',
  playerOneSide: Side.top,
  firstTurn: Side.top,
  timerMinutes: 0,
);

MatchConfig _vsMachineConfig() => const MatchConfig(
  playerOneName: 'Alice',
  playerTwoName: 'Machine',
  playerOneSide: Side.top,
  firstTurn: Side.top,
  timerMinutes: 0,
  machineSide: Side.bottom,
  difficulty: Difficulty.easy,
);

/// Taps a board node, then flushes both the immediate state change and any
/// resulting move-presentation animation. `pumpAndSettle()` alone is not
/// enough here: it only keeps pumping while the scheduler has an active
/// Ticker/AnimationController-driven frame pending, but the presentation
/// timeline deliberately uses plain `Timer`s (no vsync needed at the
/// controller layer), so a plain single-shot `Timer` scheduled a little
/// into the future doesn't register as "still animating" between pumps.
Future<void> _tapNode(WidgetTester tester, NodeId node) async {
  final boardRect = tester.getRect(find.byType(BoardWidget));
  final layout = BoardLayout.fromGraph(BoardGraph.standard(), boardRect.size);
  final local = layout.positions[node]!;
  await tester.tapAt(boardRect.topLeft + Offset(local.dx, local.dy));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<Widget> _app({MatchConfig? config}) async {
  final repos = await createTestRepositories();
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repos.settings),
      deviceLanguageCodeProvider.overrideWithValue('en'),
      profileRepositoryProvider.overrideWithValue(repos.profile),
      matchHistoryRepositoryProvider.overrideWithValue(repos.matchHistory),
      savedGameRepositoryProvider.overrideWithValue(repos.savedGame),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MatchScreen(config: config ?? _config()),
    ),
  );
}

void main() {
  testWidgets('match screen shows the turn banner and both player rails', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    expect(find.text("Alice's turn"), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('Bilal'), findsWidgets);
  });

  testWidgets(
    'tapping a piece then its target performs the move and updates the turn banner',
    (tester) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      await _tapNode(tester, 'r1c2');
      await _tapNode(tester, 'r2c2');

      expect(find.text("Bilal's turn"), findsOneWidget);
      // This exact move exposes an immediate mandatory reply capture.
      expect(find.text('Capture available — you must capture'), findsOneWidget);
    },
  );

  testWidgets(
    'pause shows the paused overlay and blocks board input until resumed',
    (tester) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();

      expect(find.text('Paused'), findsOneWidget);

      // Board input is ignored while paused.
      await _tapNode(tester, 'r1c2');
      expect(find.text("Alice's turn"), findsOneWidget);

      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      expect(find.text('Paused'), findsNothing);
    },
  );

  testWidgets(
    'resign shows a confirmation dialog and, once confirmed, the match-over dialog',
    (tester) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Resign'));
      await tester.pumpAndSettle();
      expect(find.text('Resign this match?'), findsOneWidget);

      await tester.tap(find.text('Resign').last);
      await tester.pumpAndSettle();

      expect(find.text('Bilal wins'), findsOneWidget);
      expect(find.text('Alice resigned.'), findsOneWidget);
    },
  );

  testWidgets(
    'board input is locked while a move animation is playing, then unlocked once it finishes',
    (tester) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      final boardRect = tester.getRect(find.byType(BoardWidget));
      final layout = BoardLayout.fromGraph(
        BoardGraph.standard(),
        boardRect.size,
      );
      Future<void> tapRaw(NodeId node) async {
        final local = layout.positions[node]!;
        await tester.tapAt(boardRect.topLeft + Offset(local.dx, local.dy));
      }

      await tapRaw('r1c2');
      await tester.pump();
      await tapRaw('r2c2');
      await tester
          .pump(); // apply the move synchronously; animation now playing

      expect(find.text('Move in progress'), findsOneWidget);
      expect(
        find.text("Alice's turn"),
        findsOneWidget,
        reason: 'the AnimatedSwitcher has not yet settled on the new turn text',
      );

      // A tap during playback must be ignored: the board must not react to
      // input while the opponent-move presentation is animating.
      await tapRaw('r3c2');
      await tester.pump();
      expect(
        find.text('Move in progress'),
        findsOneWidget,
        reason:
            'still mid-animation, so the tap on r3c2 must have been ignored',
      );

      // Flush the animation, then confirm the board is interactive again and
      // reflects the true post-move state.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Capture available — you must capture'), findsOneWidget);

      await tapRaw('r3c2');
      await tester.pump();
      await tapRaw('r1c2');
      await tester.pump(const Duration(seconds: 1));

      expect(find.text("Alice's turn"), findsOneWidget);
    },
  );

  testWidgets(
    'restart confirmation resets the board back to the initial position',
    (tester) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      await _tapNode(tester, 'r1c2');
      await _tapNode(tester, 'r2c2');
      expect(find.text("Bilal's turn"), findsOneWidget);

      await tester.tap(find.byTooltip('Restart'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restart').last);
      await tester.pumpAndSettle();

      expect(find.text("Alice's turn"), findsOneWidget);
    },
  );

  testWidgets(
    'vs-Machine match: after the human moves, the machine automatically '
    'thinks then replies without further input',
    (tester) async {
      await tester.pumpWidget(await _app(config: _vsMachineConfig()));
      await tester.pumpAndSettle();

      await _tapNode(tester, 'r1c2');
      await _tapNode(tester, 'r2c2');

      // The machine (bottom) now replies on its own, with no further
      // test-driven taps: flush its bounded thinking delay plus its own
      // move's presentation animation. Precise thinking-indicator timing is
      // covered deterministically at the controller level
      // (machine_controller_test.dart); this test only confirms the full
      // human-move → machine-reply round trip is wired up end to end and
      // doesn't get stuck.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('Machine is thinking'), findsNothing);
      expect(find.text("Alice's turn"), findsOneWidget);
    },
  );

  testWidgets(
    'a board node semantic label includes its position, not just its owner '
    '(Phase 7 accessibility fix)',
    (tester) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      final label = tester
          .getSemantics(find.byType(BoardWidget).first)
          .toStringDeep();
      // r1c2 (row 2, column 3, 1-indexed) holds a top bead at the start.
      expect(label, contains('row 2, column 3'));
    },
  );

  testWidgets(
    'the match screen renders without overflow under a large text scale '
    'factor',
    (tester) async {
      await tester.pumpWidget(await _app());
      tester.binding.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(
        () => tester.binding.platformDispatcher.clearTextScaleFactorTestValue(),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('high contrast changes the bead fill color used for painting', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    Color currentTopBeadColor() {
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<BoardPainter>()
          .first;
      return effectiveBeadColor(
        Side.top,
        highContrast: painter.visual.highContrast,
        brightness: Brightness.light,
      );
    }

    final before = currentTopBeadColor();

    final context = tester.element(find.byType(MatchScreen));
    ProviderScope.containerOf(context)
        .read(settingsControllerProvider.notifier)
        .setHighContrast(true);
    await tester.pumpAndSettle();

    final after = currentTopBeadColor();
    expect(after, isNot(before));
  });
}
