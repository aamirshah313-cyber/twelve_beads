import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/profile/badges.dart';

/// Localized display name/description for a badge id. Falls back to the
/// raw id (never a crash) for an id this build doesn't recognize — e.g. one
/// earned by a newer app version and later opened in an older one.
({String name, String description}) describeBadge(
  AppLocalizations l10n,
  String badgeId,
) {
  return switch (badgeId) {
    BadgeIds.firstWin => (
      name: l10n.badgeFirstWinName,
      description: l10n.badgeFirstWinDescription,
    ),
    BadgeIds.fiveMatches => (
      name: l10n.badgeFiveMatchesName,
      description: l10n.badgeFiveMatchesDescription,
    ),
    BadgeIds.captureSpecialist => (
      name: l10n.badgeCaptureSpecialistName,
      description: l10n.badgeCaptureSpecialistDescription,
    ),
    BadgeIds.threeWinStreak => (
      name: l10n.badgeThreeWinStreakName,
      description: l10n.badgeThreeWinStreakDescription,
    ),
    BadgeIds.fastFinish => (
      name: l10n.badgeFastFinishName,
      description: l10n.badgeFastFinishDescription,
    ),
    BadgeIds.patientPlayer => (
      name: l10n.badgePatientPlayerName,
      description: l10n.badgePatientPlayerDescription,
    ),
    _ => (name: badgeId, description: ''),
  };
}
