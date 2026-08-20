import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twelve_beads/core/history/match_history_controller.dart';
import 'package:twelve_beads/core/l10n/gen/app_localizations.dart';
import 'package:twelve_beads/core/profile/profile_controller.dart';
import 'package:twelve_beads/core/settings/settings_controller.dart';
import 'package:twelve_beads/features/game/application/saved_game_controller.dart';
import 'package:twelve_beads/features/profile/presentation/profile_screen.dart';

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
      home: const ProfileScreen(),
    ),
  );
}

void main() {
  testWidgets('a fresh profile shows the default display name "Player"', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    expect(find.text('Player'), findsWidgets);
  });

  testWidgets(
    'editing the display name via the edit dialog persists it through '
    "the controller and updates the screen's heading",
    (tester) async {
      await tester.pumpWidget(await _app());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Edit display name'));
      await tester.pumpAndSettle();
      expect(find.text('Display name'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Aamir');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Aamir'), findsWidgets);
      final context = tester.element(find.byType(ProfileScreen));
      expect(
        ProviderScope.containerOf(context)
            .read(profileControllerProvider)
            .displayName,
        'Aamir',
      );
    },
  );

  testWidgets('canceling the edit dialog leaves the display name unchanged', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit display name'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Should not stick');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Player'), findsWidgets);
    expect(find.text('Should not stick'), findsNothing);
  });

  testWidgets('an empty name is not saved; the previous name is kept', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit display name'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Player'), findsWidgets);
  });
}
