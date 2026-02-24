/// A post in the "Following" tab: from someone the user follows.
class FollowingPost {
  const FollowingPost({
    required this.id,
    required this.userHandle,
    required this.userAvatarUrl,
    required this.imageUrl,
    required this.locationTag,
    required this.caption,
    required this.lat,
    required this.lng,
    this.timeAgo,
  });

  final String id;
  final String userHandle;
  final String? userAvatarUrl;
  final String imageUrl;
  /// Gemini-generated location tag, e.g. "Matcha Cafe · Kyoto"
  final String locationTag;
  final String caption;
  final double lat;
  final double lng;
  /// Display label, e.g. "2h ago", "1d ago"
  final String? timeAgo;

  /// Splits [locationTag] into place name and city (e.g. "Matcha Cafe · Kyoto" → ["Matcha Cafe", "Kyoto"]).
  List<String> get placeAndCity {
    final parts = locationTag.split(' · ');
    if (parts.length >= 2) return [parts[0].trim(), parts[1].trim()];
    if (parts.isNotEmpty) return [parts[0].trim(), ''];
    return ['', ''];
  }
}

/// A pin in the "Explore" tab: AI-recommended global.
class ExplorePin {
  const ExplorePin({
    required this.id,
    required this.imageUrl,
    required this.locationLabel,
    this.curatedByGemini = false,
    this.lat,
    this.lng,
  });

  final String id;
  final String imageUrl;
  final String locationLabel;
  final bool curatedByGemini;
  final double? lat;
  final double? lng;
}

/// A pin in the "Local" tab: near user's city (mock: Istanbul).
class LocalPin {
  const LocalPin({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.distanceKm,
    this.lat,
    this.lng,
  });

  final String id;
  final String imageUrl;
  final String title;
  /// Distance string, e.g. "1.2 km away"
  final String distanceKm;
  final double? lat;
  final double? lng;
}
