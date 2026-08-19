import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/profile/profile_controller.dart';
import '../../../core/theme/app_spacing.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(profileControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final displayName = stats.displayName.isEmpty
        ? l10n.profileDefaultName
        : stats.displayName;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileScreenTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(displayName, style: textTheme.headlineSmall),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (stats.matchesPlayed == 0)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: Text(l10n.profileNoMatchesYet)),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Wrap(
                        spacing: AppSpacing.lg,
                        runSpacing: AppSpacing.md,
                        children: [
                          _Stat(
                            label: l10n.profileStatsMatches,
                            value: stats.matchesPlayed,
                          ),
                          _Stat(
                            label: l10n.profileStatsWins,
                            value: stats.wins,
                          ),
                          _Stat(
                            label: l10n.profileStatsLosses,
                            value: stats.losses,
                          ),
                          _Stat(
                            label: l10n.profileStatsDraws,
                            value: stats.draws,
                          ),
                          _Stat(
                            label: l10n.profileStatsStreak,
                            value: stats.currentStreak,
                          ),
                          _Stat(
                            label: l10n.profileStatsCaptures,
                            value: stats.totalCaptures,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.profileBadgesHeading, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                if (stats.earnedBadgeIds.isEmpty)
                  Text(l10n.profileNoBadgesYet, style: textTheme.bodyMedium)
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final badgeId in stats.earnedBadgeIds)
                        Chip(label: Text(badgeId)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: textTheme.headlineSmall),
          Text(label, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
