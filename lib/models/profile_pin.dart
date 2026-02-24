/// A pin shown on the profile: either owned by the user (My Pins) or saved from feed (Saved).
/// For Saved tab, [creatorUsername] is set (e.g. "Saved from @traveller_joe").
class ProfilePin {
  const ProfilePin({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.name,
    required this.locationLabel,
    this.lat,
    this.lng,
    this.creatorUsername,
  });

  final String id;
  final String userId;
  final String imageUrl;
  final String name;
  final String locationLabel;
  final double? lat;
  final double? lng;
  /// For saved pins: the original creator's handle, e.g. "traveller_joe".
  final String? creatorUsername;

  bool get isSavedFromFeed => creatorUsername != null;
}
