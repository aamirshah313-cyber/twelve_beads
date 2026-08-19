import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_spacing.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = ref.watch(settingsControllerProvider).languageCode;
    final languageName = languageCode == 'ur'
        ? l10n.languageNameUrdu
        : l10n.languageNameEnglish;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Center(
              child: Chip(label: Text(l10n.homeCurrentLanguage(languageName))),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HomeMenuButton(
                    icon: Icons.play_arrow_rounded,
                    label: l10n.navPlay,
                    routeName: AppRoutes.gameSetup,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _HomeMenuButton(
                    icon: Icons.menu_book_rounded,
                    label: l10n.navHowToPlay,
                    routeName: AppRoutes.rules,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _HomeMenuButton(
                    icon: Icons.person_rounded,
                    label: l10n.navProfile,
                    routeName: AppRoutes.profile,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _HomeMenuButton(
                    icon: Icons.settings_rounded,
                    label: l10n.navSettings,
                    routeName: AppRoutes.settings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeMenuButton extends StatelessWidget {
  const _HomeMenuButton({
    required this.icon,
    required this.label,
    required this.routeName,
  });

  final IconData icon;
  final String label;
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(
          AppSpacing.minTouchTarget + AppSpacing.md,
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      onPressed: () => Navigator.of(context).pushNamed(routeName),
      icon: Icon(icon),
      label: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
