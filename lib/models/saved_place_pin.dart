/// Source of the pin: user-uploaded photo vs coordinates-only (e.g. searched/added from map).
enum PinSource {
  userUploadedPhoto,
  locationCoordinates,
}

/// Premium Saved Place model for the Pinterest-style archive.
/// id, name, city, country, imageUrl, description, category, lat/lng, timestamp.
/// Metadata: [source], [isPrivate] (toggle Keep Private / Share on Profile).
class SavedPlacePin {
  const SavedPlacePin({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.source = PinSource.userUploadedPhoto,
    this.isPrivate = false,
  });

  final String id;
  final String name;
  final String city;
  final String country;
  final String imageUrl;
  final String description;
  /// One of: Museums, Nature, Food, Photo Spots, etc.
  final String category;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  /// User Uploaded Photo vs Location Coordinates only.
  final PinSource source;
  /// Keep Private = true; Share on Profile = false.
  final bool isPrivate;

  bool get isUserUploadedPhoto => source == PinSource.userUploadedPhoto;
  bool get shareOnProfile => !isPrivate;
}

/// Mock data: 5 premium travel pins for the Saved Places view.
final List<SavedPlacePin> mockSavedPlacePins = [
  SavedPlacePin(
    id: 'eiffel',
    name: 'Eiffel Tower',
    city: 'Paris',
    country: 'France',
    imageUrl: 'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?w=800',
    description: 'Iconic iron lattice tower on the Champ de Mars, symbol of Paris and one of the most recognizable structures in the world.',
    category: 'Photo Spots',
    latitude: 48.8584,
    longitude: 2.2945,
    timestamp: DateTime(2024, 3, 15),
  ),
  SavedPlacePin(
    id: 'hagia_sophia',
    name: 'Hagia Sophia',
    city: 'Istanbul',
    country: 'Turkey',
    imageUrl: 'https://images.unsplash.com/photo-1541432901042-2d8bd64b4a9b?w=800',
    description: 'Byzantine masterpiece and former cathedral, now a museum. Stunning mosaics and monumental dome.',
    category: 'Museums',
    latitude: 41.0086,
    longitude: 28.9802,
    timestamp: DateTime(2024, 4, 2),
  ),
  SavedPlacePin(
    id: 'colosseum',
    name: 'Colosseum',
    city: 'Rome',
    country: 'Italy',
    imageUrl: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800',
    description: 'Ancient Roman amphitheatre and one of the New Seven Wonders. Gladiatorial contests and public spectacles.',
    category: 'Museums',
    latitude: 41.8902,
    longitude: 12.4922,
    timestamp: DateTime(2024, 5, 10),
    source: PinSource.locationCoordinates,
    isPrivate: true,
  ),
  SavedPlacePin(
    id: 'berlin_cafe',
    name: 'Kaffee und Kuchen',
    city: 'Berlin',
    country: 'Germany',
    imageUrl: 'https://images.unsplash.com/photo-1495474474567-4c4de5f1a4a5?w=800',
    description: 'A cozy neighborhood cafe in Kreuzberg with excellent pastries and a relaxed, creative vibe.',
    category: 'Food',
    latitude: 52.4992,
    longitude: 13.4191,
    timestamp: DateTime(2024, 6, 1),
  ),
  SavedPlacePin(
    id: 'bali_beach',
    name: 'Hidden Beach, Uluwatu',
    city: 'Bali',
    country: 'Indonesia',
    imageUrl: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800',
    description: 'Secluded cove with turquoise water and white sand, surrounded by cliffs. Perfect for a quiet escape.',
    category: 'Nature',
    latitude: -8.8292,
    longitude: 115.0869,
    timestamp: DateTime(2024, 7, 20),
  ),
  SavedPlacePin(
    id: 'paris_cafe',
    name: 'Café de Flore',
    city: 'Paris',
    country: 'France',
    imageUrl: 'https://images.unsplash.com/photo-1495474474567-4c4de5f1a4a5?w=800',
    description: 'Historic café in Saint-Germain. Perfect for people-watching and classic Parisian atmosphere.',
    category: 'Food',
    latitude: 48.8540,
    longitude: 2.3322,
    timestamp: DateTime(2024, 3, 18),
  ),
  SavedPlacePin(
    id: 'istanbul_bazaar',
    name: 'Grand Bazaar',
    city: 'Istanbul',
    country: 'Turkey',
    imageUrl: 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=800',
    description: 'One of the world\'s oldest covered markets. Labyrinth of shops, spices, and crafts.',
    category: 'Photo Spots',
    latitude: 41.0106,
    longitude: 28.9682,
    timestamp: DateTime(2024, 4, 5),
  ),
  SavedPlacePin(
    id: 'santorini_beach',
    name: 'Red Beach, Santorini',
    city: 'Santorini',
    country: 'Greece',
    imageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
    description: 'Dramatic red volcanic sand and cliffs. Unforgettable Aegean views.',
    category: 'Nature',
    latitude: 36.3492,
    longitude: 25.4422,
    timestamp: DateTime(2024, 7, 25),
  ),
];

