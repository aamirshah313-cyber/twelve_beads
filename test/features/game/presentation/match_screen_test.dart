import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_beads/core/l10n/gen/app_localizations.dart';
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

Future<void> _tapNode(WidgetTester tester, NodeId node) async {
  final boardRect = tester.getRect(find.byType(BoardWidget));
  final layout = BoardLayout.fromGraph(BoardGraph.standard(), boardRect.size);
  final local = layout.positions[node]!;
  await tester.tapAt(boardRect.topLeft + Offset(local.dx, local.dy));
  await tester.pumpAndSettle();
}

Widget _app() => ProviderScope(
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MatchScreen(config: _config()),
  ),
);

void main() {
  testWidgets('match screen shows the turn banner and both player rails', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text("Alice's turn"), findsOneWidget);
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('Bilal'), findsWidgets);
  });

  testWidgets(
    'tapping a piece then its target performs the move and updates the turn banner',
    (tester) async {
      await tester.pumpWidget(_app());
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
      await tester.pumpWidget(_app());
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
      await tester.pumpWidget(_app());
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
    'restart confirmation resets the board back to the initial position',
    (tester) async {
      await tester.pumpWidget(_app());
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
