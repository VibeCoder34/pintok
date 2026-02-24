import 'collection.dart';

/// Mock user profile for "My Journey" screen.
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

/// Mock profile: @PintokExplorer, bio, stats.
const mockUserProfile = UserProfile(
  username: 'PintokExplorer',
  bio: 'Exploring hidden gems with Gemini 3.1 AI.',
  avatarUrl: null,
  pinsCount: 12,
  collectionsCount: 3,
  impactCount: 284,
);

/// Mock collections for My Journey: Paris Classics, Istanbul Street Food, Aegean Blue.
final List<Collection> mockProfileCollections = [
  Collection(
    id: 'paris_classics',
    name: 'Paris Classics',
    pinIds: ['eiffel', 'paris_cafe'],
    isPrivate: false,
    shareSlug: 'paris-classics-x7k2',
  ),
  Collection(
    id: 'istanbul_street_food',
    name: 'Istanbul Street Food',
    pinIds: ['hagia_sophia', 'istanbul_bazaar'],
    isPrivate: false,
    shareSlug: 'istanbul-street-food-m4n9',
  ),
  Collection(
    id: 'aegean_blue',
    name: 'Aegean Blue',
    pinIds: ['bali_beach', 'santorini_beach'],
    isPrivate: true,
    shareSlug: null,
  ),
];
