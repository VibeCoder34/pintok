class UserProfile {
  const UserProfile({
    required this.username,
    required this.bio,
    this.avatarUrl,
    required this.pinsCount,
    required this.collectionsCount,
    required this.impactCount,
  });

  final String username;
  final String bio;
  final String? avatarUrl;
  final int pinsCount;
  final int collectionsCount;
  /// Total views/saves by others.
  final int impactCount;
}
