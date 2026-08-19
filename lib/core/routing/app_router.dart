import 'package:flutter/material.dart';

import '../../features/game/presentation/game_setup_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/rules/presentation/rules_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

/// Route names for the Phase 1 navigation shell. A plain named-route table
/// is enough for five reachable screens with no deep-link requirements yet;
/// this can grow into a richer router in a later phase if match resume
/// deep-links are added.
class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const gameSetup = '/play';
  static const rules = '/rules';
  static const profile = '/profile';
  static const settings = '/settings';
}

final Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.home: (context) => const HomeScreen(),
  AppRoutes.gameSetup: (context) => const GameSetupScreen(),
  AppRoutes.rules: (context) => const RulesScreen(),
  AppRoutes.profile: (context) => const ProfileScreen(),
  AppRoutes.settings: (context) => const SettingsScreen(),
};
