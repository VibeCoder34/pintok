import 'saved_place_pin.dart';

/// A folder of saved pins (e.g. "Paris Trip", "Best Coffee Spots").
/// Cover photo comes from the first pin in the collection.
class Collection {
  const Collection({
    required this.id,
    required this.name,
    required this.pinIds,
    this.coverImageUrl,
    this.isPrivate = false,
    this.shareSlug,
  });

  final String id;
  final String name;
  /// IDs of [SavedPlacePin] in this collection. First pin's image used as cover if [coverImageUrl] is null.
  final List<String> pinIds;
  /// Optional explicit cover; otherwise first pin's imageUrl.
  final String? coverImageUrl;
  final bool isPrivate;
  /// Unique slug for sharing (e.g. "paris-vibes-x7k2"). Null if never shared.
  final String? shareSlug;
}

/// Mock collections: Paris Vibes 🇫🇷, Istanbul Hidden Gems 🇹🇷, Dream Beaches 🌴.
final List<Collection> mockCollections = [
  Collection(
    id: 'paris_vibes',
    name: 'Paris Vibes 🇫🇷',
    pinIds: ['eiffel', 'paris_cafe'],
    isPrivate: false,
    shareSlug: 'paris-vibes-x7k2',
  ),
  Collection(
    id: 'istanbul_gems',
    name: 'Istanbul Hidden Gems 🇹🇷',
    pinIds: ['hagia_sophia', 'istanbul_bazaar'],
    isPrivate: false,
    shareSlug: 'istanbul-gems-m4n9',
  ),
  Collection(
    id: 'dream_beaches',
    name: 'Dream Beaches 🌴',
    pinIds: ['bali_beach', 'santorini_beach'],
    isPrivate: false,
    shareSlug: 'dream-beaches-p2q8',
  ),
];

/// Resolve pin IDs to [SavedPlacePin] from [mockSavedPlacePins].
List<SavedPlacePin> pinsForCollection(Collection c) {
  final idSet = c.pinIds.toSet();
  return mockSavedPlacePins.where((p) => idSet.contains(p.id)).toList();
}

SavedPlacePin? pinById(String id) {
  try {
    return mockSavedPlacePins.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
}

/// Cover image URL for a collection (first pin's image or explicit cover).
String? coverImageForCollection(Collection c, {List<SavedPlacePin>? allPins}) {
  if (c.coverImageUrl != null && c.coverImageUrl!.isNotEmpty) return c.coverImageUrl;
  final pins = allPins ?? pinsForCollection(c);
  return pins.isNotEmpty ? pins.first.imageUrl : null;
}
