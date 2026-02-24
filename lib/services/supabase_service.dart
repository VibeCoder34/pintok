import '../models/profile_pin.dart';

/// Service for pins and bookmarks. Use Supabase when configured; otherwise mock.
/// Tables: pins (id, user_id, image_url, name, location_label, lat, lng, ...), bookmarks (user_id, pin_id).
class SupabaseService {
  SupabaseService({this.currentUserId});

  /// Current logged-in user id. Mock: 'me'
  final String? currentUserId;

  static const _mockUserId = 'me';

  /// My Pins: pins where user_id matches current user (scanned with Gemini and added).
  Future<List<ProfilePin>> getMyPins() async {
    final uid = currentUserId ?? _mockUserId;
    return _mockMyPins.where((p) => p.userId == uid).toList();
  }

  /// Saved Pins: pins the user bookmarked (join bookmarks + pins). Includes creatorUsername.
  Future<List<ProfilePin>> getSavedPins() async {
    final uid = currentUserId ?? _mockUserId;
    final savedIds = _bookmarks[uid] ?? {};
    return _mockSavedPins
        .where((p) => savedIds.contains(p.id))
        .map((p) => p)
        .toList();
  }

  /// Toggle bookmark for current user. Returns true if now bookmarked, false if removed.
  Future<bool> toggleBookmark(String pinId) async {
    final uid = currentUserId ?? _mockUserId;
    final set = _bookmarks.putIfAbsent(uid, () => <String>{});
    if (set.contains(pinId)) {
      set.remove(pinId);
      return false;
    }
    set.add(pinId);
    return true;
  }

  /// Check if a pin is bookmarked by current user.
  Future<bool> isBookmarked(String pinId) async {
    final uid = currentUserId ?? _mockUserId;
    return (_bookmarks[uid] ?? {}).contains(pinId);
  }

  /// In-memory bookmarks for mock: map of userId -> set of pinIds.
  static final Map<String, Set<String>> _bookmarks = {
    _mockUserId: {'saved_1', 'saved_2'},
  };

  /// Mock "My Pins" — user's own pins (from Gemini scan).
  static final List<ProfilePin> _mockMyPins = [
    const ProfilePin(
      id: 'my_1',
      userId: _mockUserId,
      imageUrl: 'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?w=800',
      name: 'Eiffel Tower',
      locationLabel: 'Paris, France',
      lat: 48.8584,
      lng: 2.2945,
    ),
    const ProfilePin(
      id: 'my_2',
      userId: _mockUserId,
      imageUrl: 'https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?w=800',
      name: 'Hagia Sophia',
      locationLabel: 'Istanbul, Turkey',
      lat: 41.0086,
      lng: 28.9802,
    ),
    const ProfilePin(
      id: 'my_3',
      userId: _mockUserId,
      imageUrl: 'https://images.unsplash.com/photo-1495474474567-4c4de5f1a4a5?w=800',
      name: 'Matcha Cafe',
      locationLabel: 'Kyoto, Japan',
      lat: 35.0016,
      lng: 135.7756,
    ),
  ];

  /// Mock "Saved" feed pins (from Explore/Following). creatorUsername for "Saved from @x".
  static final List<ProfilePin> _mockSavedPins = [
    const ProfilePin(
      id: 'saved_1',
      userId: 'other',
      imageUrl: 'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800',
      name: 'Salinas Grandes',
      locationLabel: 'Argentina',
      lat: -23.6345,
      lng: -65.9432,
      creatorUsername: 'travel_guru',
    ),
    const ProfilePin(
      id: 'saved_2',
      userId: 'other',
      imageUrl: 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800',
      name: 'Starfield Library',
      locationLabel: 'Seoul, South Korea',
      lat: 37.5133,
      lng: 127.1028,
      creatorUsername: 'wanderlust_em',
    ),
    const ProfilePin(
      id: 'saved_3',
      userId: 'other',
      imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800',
      name: 'Hidden Beach',
      locationLabel: 'Bali, Indonesia',
      lat: -8.8292,
      lng: 115.0869,
      creatorUsername: 'cafe_hopper',
    ),
  ];
}
