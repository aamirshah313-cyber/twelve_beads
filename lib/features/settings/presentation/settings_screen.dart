import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/profile/profile_controller.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/app_spacing.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreenTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(l10n.settingsLanguageLabel, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                DropdownMenu<String>(
                  initialSelection: settings.languageCode,
                  onSelected: (value) {
                    if (value != null) controller.setLanguageCode(value);
                  },
                  dropdownMenuEntries: [
                    DropdownMenuEntry(
                      value: 'en',
                      label: l10n.languageNameEnglish,
                    ),
                    DropdownMenuEntry(
                      value: 'ur',
                      label: l10n.languageNameUrdu,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsSoundLabel),
                  value: settings.soundOn,
                  onChanged: controller.setSoundOn,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsHapticsLabel),
                  value: settings.hapticsOn,
                  onChanged: controller.setHapticsOn,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsHighContrastLabel),
                  value: settings.highContrast,
                  onChanged: controller.setHighContrast,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.settingsReducedMotionLabel,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<ReducedMotionPreference>(
                  segments: [
                    ButtonSegment(
                      value: ReducedMotionPreference.system,
                      label: Text(l10n.reducedMotionSystem),
                    ),
                    ButtonSegment(
                      value: ReducedMotionPreference.on,
                      label: Text(l10n.commonOn),
                    ),
                    ButtonSegment(
                      value: ReducedMotionPreference.off,
                      label: Text(l10n.commonOff),
                    ),
                  ],
                  selected: {settings.reducedMotion},
                  onSelectionChanged: (selection) =>
                      controller.setReducedMotion(selection.first),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.settingsVisualQualityLabel,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<VisualQuality>(
                  segments: [
                    ButtonSegment(
                      value: VisualQuality.auto,
                      label: Text(l10n.visualQualityAuto),
                    ),
                    ButtonSegment(
                      value: VisualQuality.low,
                      label: Text(l10n.visualQualityLow),
                    ),
                    ButtonSegment(
                      value: VisualQuality.standard,
                      label: Text(l10n.visualQualityStandard),
                    ),
                    ButtonSegment(
                      value: VisualQuality.high,
                      label: Text(l10n.visualQualityHigh),
                    ),
                  ],
                  selected: {settings.visualQuality},
                  onSelectionChanged: (selection) =>
                      controller.setVisualQuality(selection.first),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.settingsTimerDefaultLabel,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownMenu<int>(
                  initialSelection: settings.timerDefaultMinutes,
                  onSelected: (value) {
                    if (value != null) controller.setTimerDefaultMinutes(value);
                  },
                  dropdownMenuEntries: [
                    DropdownMenuEntry(value: 0, label: l10n.timerOff),
                    const DropdownMenuEntry(value: 1, label: '1'),
                    const DropdownMenuEntry(value: 3, label: '3'),
                    const DropdownMenuEntry(value: 5, label: '5'),
                    const DropdownMenuEntry(value: 10, label: '10'),
                    const DropdownMenuEntry(value: 15, label: '15'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                Divider(),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.settingsPrivacyHeading, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.settingsPrivacyBody, style: textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    minimumSize: const Size.fromHeight(
                      AppSpacing.minTouchTarget,
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(l10n.settingsDeleteLocalData),
                  onPressed: () => _confirmDelete(context, ref, l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsDeleteConfirmTitle),
        content: Text(l10n.settingsDeleteConfirmBody),
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
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final deviceLanguageCode = ref.read(deviceLanguageCodeProvider);
    await ref
        .read(settingsControllerProvider.notifier)
        .deleteAllAndReset(deviceLanguageCode: deviceLanguageCode);
    await ref.read(profileControllerProvider.notifier).deleteAllAndReset();
  }
}
