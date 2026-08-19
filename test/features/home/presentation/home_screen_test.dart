import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_beads/core/history/match_history_controller.dart';
import 'package:twelve_beads/core/l10n/gen/app_localizations.dart';
import 'package:twelve_beads/core/profile/profile_controller.dart';
import 'package:twelve_beads/core/settings/settings_controller.dart';
import 'package:twelve_beads/features/game/application/match_config.dart';
import 'package:twelve_beads/features/game/application/saved_game.dart';
import 'package:twelve_beads/features/game/application/saved_game_controller.dart';
import 'package:twelve_beads/features/home/presentation/home_screen.dart';
import 'package:twelve_beads/features/game/presentation/match_screen.dart';
import 'package:twelve_beads/game/engine/game_action.dart';
import 'package:twelve_beads/game/engine/side.dart';

import '../../../support/repository_overrides.dart';

const _config = MatchConfig(
  playerOneName: 'Alice',
  playerTwoName: 'Bilal',
  playerOneSide: Side.top,
  firstTurn: Side.top,
  timerMinutes: 0,
);

Future<Widget> _app({SavedGameSnapshot? saved}) async {
  final repos = await createTestRepositories();
  if (saved != null) {
    await repos.savedGame.save(saved);
  }
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
      home: const HomeScreen(),
    ),
  );
}

void main() {
  testWidgets('no resume card is shown when there is no saved match', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    expect(find.text('You have a match in progress'), findsNothing);
  });

  testWidgets('a saved match shows Resume/Discard, and Resume opens '
      'MatchScreen with the saved progress', (tester) async {
    final saved = SavedGameSnapshot(
      config: _config,
      actionLog: const [MoveAction(from: 'r1c2', to: 'r2c2')],
      topRemaining: Duration.zero,
      bottomRemaining: Duration.zero,
      startedAt: DateTime(2026, 1, 1),
      savedAt: DateTime(2026, 1, 1, 0, 5),
    );
    await tester.pumpWidget(await _app(saved: saved));
    await tester.pumpAndSettle();

    expect(find.text('You have a match in progress'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();

    expect(find.byType(MatchScreen), findsOneWidget);
    // Landed paused, per the resume contract.
    expect(find.text('Paused'), findsOneWidget);
  });

  testWidgets('Discard shows a confirmation and then clears the saved match', (
    tester,
  ) async {
    final saved = SavedGameSnapshot(
      config: _config,
      actionLog: const [MoveAction(from: 'r1c2', to: 'r2c2')],
      topRemaining: Duration.zero,
      bottomRemaining: Duration.zero,
      startedAt: DateTime(2026, 1, 1),
      savedAt: DateTime(2026, 1, 1, 0, 5),
    );
    await tester.pumpWidget(await _app(saved: saved));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Discard this match?'), findsOneWidget);

    await tester.tap(find.text('Discard').last);
    await tester.pumpAndSettle();

    expect(find.text('You have a match in progress'), findsNothing);
  });
}
