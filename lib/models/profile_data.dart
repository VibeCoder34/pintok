class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.bio,
    this.avatarUrl,
    this.avatarKey,
    required this.pinsCount,
    required this.collectionsCount,
    required this.impactCount,
    this.aiScansUsed = 0,
    this.aiScansLimit,
  });

  final String displayName;
  final String bio;
  final String? avatarUrl;
  /// Bitmoji key: gencerkek, genckadin, yaslierkek, yaslikadin. When set, shown as profile photo.
  final String? avatarKey;
  final int pinsCount;
  final int collectionsCount;
  /// Total views/saves by others.
  final int impactCount;
  /// AI fuel: scans used this period.
  final int aiScansUsed;
  /// AI fuel: max allowed scans (null = unknown/unlimited).
  final int? aiScansLimit;
}
