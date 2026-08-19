import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:twelve_beads/core/l10n/gen/app_localizations.dart';
import 'package:twelve_beads/core/profile/profile_controller.dart';
import 'package:twelve_beads/core/profile/profile_repository.dart';
import 'package:twelve_beads/core/routing/app_router.dart';
import 'package:twelve_beads/core/settings/settings_controller.dart';
import 'package:twelve_beads/core/settings/settings_repository.dart';
import 'package:twelve_beads/main.dart';

Future<ProviderScope> _buildApp({required String deviceLanguageCode}) async {
  SharedPreferences.setMockInitialValues({});
  final settingsRepository = await SettingsRepository.create();
  final profileRepository = await ProfileRepository.create();
  return ProviderScope(
    overrides: [
      deviceLanguageCodeProvider.overrideWithValue(deviceLanguageCode),
      settingsRepositoryProvider.overrideWithValue(settingsRepository),
      profileRepositoryProvider.overrideWithValue(profileRepository),
    ],
    child: const TwelveBeadsApp(),
  );
}

void main() {
  testWidgets('offline launch shows the home screen with all nav entries', (
    tester,
  ) async {
    await tester.pumpWidget(await _buildApp(deviceLanguageCode: 'en'));
    await tester.pumpAndSettle();

    expect(find.text('Twelve Beads'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('How to Play'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('English locale renders left-to-right', (tester) async {
    await tester.pumpWidget(await _buildApp(deviceLanguageCode: 'en'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(context), TextDirection.ltr);
  });

  testWidgets('Urdu locale renders right-to-left with translated home labels', (
    tester,
  ) async {
    await tester.pumpWidget(await _buildApp(deviceLanguageCode: 'ur'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(context), TextDirection.rtl);

    expect(find.text('بارہ گوٹی'), findsOneWidget);
    expect(find.text('کھیلیں'), findsOneWidget);
  });

  testWidgets('all five Phase 1 screens are reachable via navigation', (
    tester,
  ) async {
    await tester.pumpWidget(await _buildApp(deviceLanguageCode: 'en'));
    await tester.pumpAndSettle();

    for (final route in [
      AppRoutes.gameSetup,
      AppRoutes.rules,
      AppRoutes.profile,
      AppRoutes.settings,
    ]) {
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      navigator.pushNamed(route);
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
      navigator.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('switching language updates the UI live without restart', (
    tester,
  ) async {
    await tester.pumpWidget(await _buildApp(deviceLanguageCode: 'en'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets); // app bar title, English.

    final context = tester.element(find.byType(Scaffold).first);
    ProviderScope.containerOf(context)
        .read(settingsControllerProvider.notifier)
        .setLanguageCode('ur');
    await tester.pumpAndSettle();

    // App bar title, now Urdu, same screen instance, no restart.
    expect(find.text('ترتیبات'), findsWidgets);
  });

  test('AppLocalizations supports both required locales', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode),
      containsAll(['en', 'ur']),
    );
  });
}
