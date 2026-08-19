import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twelve_beads/core/l10n/gen/app_localizations.dart';
import 'package:twelve_beads/core/settings/settings_controller.dart';
import 'package:twelve_beads/core/settings/settings_repository.dart';
import 'package:twelve_beads/features/game/application/match_config.dart';
import 'package:twelve_beads/features/game/presentation/board_widget.dart';
import 'package:twelve_beads/features/game/presentation/match_screen.dart';
import 'package:twelve_beads/game/board/board_graph.dart';
import 'package:twelve_beads/features/game/presentation/board_layout.dart';
import 'package:twelve_beads/game/engine/side.dart';

MatchConfig _config() => const MatchConfig(
  playerOneName: 'Alice',
  playerTwoName: 'Bilal',
  playerOneSide: Side.top,
  firstTurn: Side.top,
  timerMinutes: 0,
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

Future<Widget> _app() async {
  SharedPreferences.setMockInitialValues({});
  final settingsRepository = await SettingsRepository.create();
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(settingsRepository),
      deviceLanguageCodeProvider.overrideWithValue('en'),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MatchScreen(config: _config()),
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
}
