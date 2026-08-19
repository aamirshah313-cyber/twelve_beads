import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/history/match_history_controller.dart';
import '../../../core/history/match_record.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/profile/profile_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../game/ai/difficulty.dart';
import 'badge_presentation.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(profileControllerProvider);
    final history = ref.watch(matchHistoryControllerProvider);
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
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final badgeId in stats.earnedBadgeIds)
                        _BadgeChip(badgeId: badgeId, l10n: l10n),
                    ],
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.profileHistoryHeading, style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                if (history.isEmpty)
                  Text(l10n.profileNoMatchesYet, style: textTheme.bodyMedium)
                else
                  Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final record in history.reversed.take(10))
                          _MatchHistoryTile(record: record, l10n: l10n),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badgeId, required this.l10n});

  final String badgeId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final described = describeBadge(l10n, badgeId);
    return Tooltip(
      message: described.description,
      child: Chip(
        avatar: const Icon(Icons.emoji_events_rounded, size: 18),
        label: Text(described.name),
      ),
    );
  }
}

class _MatchHistoryTile extends StatelessWidget {
  const _MatchHistoryTile({required this.record, required this.l10n});

  final MatchRecord record;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final outcomeText = switch (record.outcome) {
      MatchOutcome.win => l10n.historyOutcomeWin,
      MatchOutcome.loss => l10n.historyOutcomeLoss,
      MatchOutcome.draw => l10n.historyOutcomeDraw,
    };
    final outcomeColor = switch (record.outcome) {
      MatchOutcome.win => Colors.green,
      MatchOutcome.loss => Theme.of(context).colorScheme.error,
      MatchOutcome.draw => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final difficultyText = switch (record.difficulty) {
      null => null,
      final difficulty => switch (difficulty) {
        Difficulty.easy => l10n.difficultyEasy,
        Difficulty.medium => l10n.difficultyMedium,
        Difficulty.difficult => l10n.difficultyDifficult,
      },
    };
    final opponentText = record.mode == MatchMode.vsMachine
        ? l10n.historyOpponentMachine(difficultyText ?? '')
        : l10n.historyOpponentPlayer(record.playerTwoName);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: outcomeColor,
        child: Text(
          outcomeText.substring(0, 1),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text('$outcomeText · $opponentText'),
      subtitle: Text(
        '${DateFormat.yMMMd(l10n.localeName).format(record.endedAt)} · '
        '${l10n.historyMoveCount(record.moveCount)}',
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
