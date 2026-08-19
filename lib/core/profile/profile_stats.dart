/// Aggregate local statistics for the default profile.
///
/// Phase 1 only establishes the persisted shape and its zero-state
/// presentation; match finalization (Phase 6) is what will ever increment
/// these values.
class ProfileStats {
  final String displayName;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final int currentStreak;
  final int totalCaptures;
  final List<String> earnedBadgeIds;

  const ProfileStats({
    required this.displayName,
    required this.matchesPlayed,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.currentStreak,
    required this.totalCaptures,
    required this.earnedBadgeIds,
  });

  /// [displayName] is empty by default (rather than a hardcoded English
  /// word) so the UI can show a localized placeholder label until the
  /// player sets a real name.
  factory ProfileStats.defaultProfile({String displayName = ''}) =>
      ProfileStats(
        displayName: displayName,
        matchesPlayed: 0,
        wins: 0,
        losses: 0,
        draws: 0,
        currentStreak: 0,
        totalCaptures: 0,
        earnedBadgeIds: const [],
      );

  Map<String, Object?> toJson() => {
    'displayName': displayName,
    'matchesPlayed': matchesPlayed,
    'wins': wins,
    'losses': losses,
    'draws': draws,
    'currentStreak': currentStreak,
    'totalCaptures': totalCaptures,
    'earnedBadgeIds': earnedBadgeIds,
  };

  factory ProfileStats.fromJson(Map<String, Object?> json) {
    final fallback = ProfileStats.defaultProfile();
    return ProfileStats(
      displayName: json['displayName'] as String? ?? fallback.displayName,
      matchesPlayed: json['matchesPlayed'] as int? ?? fallback.matchesPlayed,
      wins: json['wins'] as int? ?? fallback.wins,
      losses: json['losses'] as int? ?? fallback.losses,
      draws: json['draws'] as int? ?? fallback.draws,
      currentStreak: json['currentStreak'] as int? ?? fallback.currentStreak,
      totalCaptures: json['totalCaptures'] as int? ?? fallback.totalCaptures,
      earnedBadgeIds:
          (json['earnedBadgeIds'] as List?)?.cast<String>() ??
          fallback.earnedBadgeIds,
    );
  }
}
