import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_beads/core/history/match_history_controller.dart';
import 'package:twelve_beads/core/l10n/gen/app_localizations.dart';
import 'package:twelve_beads/core/profile/profile_controller.dart';
import 'package:twelve_beads/core/settings/settings_controller.dart';
import 'package:twelve_beads/features/game/application/saved_game_controller.dart';
import 'package:twelve_beads/features/game/application/match_config.dart';
import 'package:twelve_beads/features/game/presentation/game_setup_screen.dart';
import 'package:twelve_beads/features/game/presentation/match_screen.dart';
import 'package:twelve_beads/game/engine/side.dart';

import '../../../support/repository_overrides.dart';

Future<Widget> _app() async {
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
      home: const GameSetupScreen(),
    ),
  );
}

void main() {
  testWidgets(
    'the per-move timer picker is present alongside the total timer, and '
    'leaving both off starts a match with no clock shown',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      expect(find.text('Timer'), findsOneWidget);
      expect(find.text('Per-move timer'), findsOneWidget);
      expect(find.byType(DropdownMenu<int>), findsNWidgets(2));

      await tester.tap(find.text('Start Match'));
      await tester.pumpAndSettle();

      expect(find.byType(MatchScreen), findsOneWidget);
      // With both timers left off, no mm:ss countdown should render.
      expect(find.textContaining(RegExp(r'^\d{2}:\d{2}$')), findsNothing);
    },
  );

  testWidgets(
    'a MatchConfig with a per-move budget shows it on the player rail '
    '(confirms MatchScreen renders whatever config it is given — engine-'
    'level per-move correctness is covered by match_controller_test.dart)',
    (tester) async {
      final repos = await createTestRepositories();
      const config = MatchConfig(
        playerOneName: 'Alice',
        playerTwoName: 'Bilal',
        playerOneSide: Side.top,
        firstTurn: Side.top,
        timerMinutes: 0,
        perMoveSeconds: 30,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(repos.settings),
            deviceLanguageCodeProvider.overrideWithValue('en'),
            profileRepositoryProvider.overrideWithValue(repos.profile),
            matchHistoryRepositoryProvider.overrideWithValue(
              repos.matchHistory,
            ),
            savedGameRepositoryProvider.overrideWithValue(repos.savedGame),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const MatchScreen(config: config),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('(00:30)'), findsWidgets);
    },
  );
}
