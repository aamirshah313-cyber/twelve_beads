import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../game/application/saved_game_controller.dart';
import '../../game/presentation/match_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = ref.watch(settingsControllerProvider).languageCode;
    final languageName = languageCode == 'ur'
        ? l10n.languageNameUrdu
        : l10n.languageNameEnglish;
    final savedGame = ref.watch(savedGameControllerProvider);

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
                  if (savedGame != null) ...[
                    _ResumeMatchCard(l10n: l10n),
                    const SizedBox(height: AppSpacing.lg),
                  ],
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

class _ResumeMatchCard extends ConsumerWidget {
  const _ResumeMatchCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.resumeMatchAvailableTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _resume(context, ref),
                    child: Text(l10n.resumeMatchButton),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmDiscard(context, ref),
                    child: Text(l10n.discardMatchButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resume(BuildContext context, WidgetRef ref) {
    final snapshot = ref.read(savedGameControllerProvider);
    if (snapshot == null) return;
    ref.read(pendingResumeSnapshotProvider.notifier).set(snapshot);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MatchScreen(config: snapshot.config)),
    );
  }

  Future<void> _confirmDiscard(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.discardMatchConfirmTitle),
        content: Text(l10n.discardMatchConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.discardMatchButton),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(savedGameControllerProvider.notifier).clear();
    }
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
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      onPressed: () => Navigator.of(context).pushNamed(routeName),
      icon: Icon(icon),
      label: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
