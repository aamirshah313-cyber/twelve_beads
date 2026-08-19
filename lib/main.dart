import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/history/match_history_controller.dart';
import 'core/history/match_history_repository.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/profile/profile_controller.dart';
import 'core/profile/profile_repository.dart';
import 'core/routing/app_router.dart';
import 'core/settings/app_settings.dart';
import 'core/settings/settings_controller.dart';
import 'core/settings/settings_repository.dart';
import 'core/theme/app_theme.dart';
import 'features/game/application/saved_game_controller.dart';
import 'features/game/application/saved_game_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final deviceLanguageCode = ui.PlatformDispatcher.instance.locale.languageCode;
  final settingsRepository = await SettingsRepository.create();
  final profileRepository = await ProfileRepository.create();
  final matchHistoryRepository = await MatchHistoryRepository.create();
  final savedGameRepository = await SavedGameRepository.create();

  runApp(
    ProviderScope(
      overrides: [
        deviceLanguageCodeProvider.overrideWithValue(deviceLanguageCode),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        profileRepositoryProvider.overrideWithValue(profileRepository),
        matchHistoryRepositoryProvider.overrideWithValue(
          matchHistoryRepository,
        ),
        savedGameRepositoryProvider.overrideWithValue(savedGameRepository),
      ],
      child: const TwelveBeadsApp(),
    ),
  );
}

class TwelveBeadsApp extends ConsumerWidget {
  const TwelveBeadsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(
        brightness: Brightness.light,
        highContrast: settings.highContrast,
        languageCode: settings.languageCode,
      ),
      darkTheme: buildAppTheme(
        brightness: Brightness.dark,
        highContrast: settings.highContrast,
        languageCode: settings.languageCode,
      ),
      themeMode: ThemeMode.system,
      locale: Locale(settings.languageCode),
      supportedLocales: AppSettings.supportedLanguageCodes.map(Locale.new),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      initialRoute: AppRoutes.home,
      routes: appRoutes,
      builder: (context, child) {
        // Reduced-motion preference: when explicitly set, override the
        // platform's reported accessibility flag rather than only following
        // it, per the "follow system, on, or off" tri-state setting.
        final mediaQuery = MediaQuery.of(context);
        final disableAnimations = switch (settings.reducedMotion) {
          ReducedMotionPreference.system => mediaQuery.disableAnimations,
          ReducedMotionPreference.on => true,
          ReducedMotionPreference.off => false,
        };
        return MediaQuery(
          data: mediaQuery.copyWith(disableAnimations: disableAnimations),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
