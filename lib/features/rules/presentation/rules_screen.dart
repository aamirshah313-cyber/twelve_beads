import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rulesScreenTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Center(child: Chip(label: Text(l10n.rulesVariantLabel))),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(l10n.rulesBoardHeading, style: textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.rulesBoardBody, style: textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.rulesMovementHeading, style: textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.rulesMovementBody, style: textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.rulesWinningHeading, style: textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.rulesWinningBody, style: textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  color: colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                l10n.rulesOpenQuestionsHeading,
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.rulesOpenQuestionsBody,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
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
