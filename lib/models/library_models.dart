import 'package:flutter/foundation.dart';

@immutable
class Collection {
  const Collection({
    required this.id,
    required this.name,
    required this.coverImageUrl,
    required this.pinCount,
    this.coverColor,
  });

  final String id;
  final String name;
  final String coverImageUrl;
  final int pinCount;
  /// Hex color (e.g. "5E35B1") for card background when no cover image.
  final String? coverColor;
}

@immutable
class SavedPin {
  const SavedPin({
    required this.id,
    required this.name,
    required this.locationName,
    required this.imageUrl,
    required this.collectionId,
    required this.description,
    required this.dateAdded,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String locationName;
  final String imageUrl;
  final String collectionId;
  final String description;
  final DateTime dateAdded;
  final double latitude;
  final double longitude;
}

/// Mock collections for Library / Journeys.
const mockCollections = <Collection>[
  Collection(
    id: 'c1',
    name: 'Paris 2026',
    pinCount: 4,
    coverImageUrl:
        'https://images.unsplash.com/photo-1543340713-1bf75c5fafa8?auto=format&fit=crop&w=1200&q=80',
  ),
  Collection(
    id: 'c2',
    name: 'Best Coffee Spots',
    pinCount: 12,
    coverImageUrl:
        'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1200&q=80',
  ),
  Collection(
    id: 'c3',
    name: 'Hidden Gems Istanbul',
    pinCount: 7,
    coverImageUrl:
        'https://images.unsplash.com/photo-1580492495332-65f4chealthy?auto=format&fit=crop&w=1200&q=80',
  ),
];

/// Mock pins, keyed by [collectionId].
final mockSavedPins = <SavedPin>[
  SavedPin(
    id: 'p1',
    name: 'Sunset at Trocadéro',
    locationName: 'Trocadéro Gardens',
    imageUrl:
        'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=1200&q=80',
    collectionId: 'c1',
    description:
        'Golden hour over the Eiffel Tower from the classic Trocadéro viewpoint.',
    dateAdded: DateTime(2026, 6, 4),
    latitude: 48.8625,
    longitude: 2.2876,
  ),
  SavedPin(
    id: 'p2',
    name: 'Seine River Lights',
    locationName: 'Pont Alexandre III',
    imageUrl:
        'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=1200&q=80',
    collectionId: 'c1',
    description:
        'Night cruise lights reflecting off the Seine near Pont Alexandre III.',
    dateAdded: DateTime(2026, 6, 5),
    latitude: 48.8638,
    longitude: 2.3130,
  ),
  SavedPin(
    id: 'p3',
    name: 'Montmartre Viewpoint',
    locationName: 'Sacré-Cœur',
    imageUrl:
        'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?auto=format&fit=crop&w=1200&q=80',
    collectionId: 'c1',
    description:
        'Panoramic rooftop view of Paris from the steps of Sacré-Cœur.',
    dateAdded: DateTime(2026, 6, 6),
    latitude: 48.8867,
    longitude: 2.3431,
  ),
  SavedPin(
    id: 'p4',
    name: 'Moonlit Eiffel',
    locationName: 'Champ de Mars',
    imageUrl:
        'https://images.unsplash.com/photo-1528818955841-a7f1425131b5?auto=format&fit=crop&w=1200&q=80',
    collectionId: 'c1',
    description:
        'The Eiffel Tower sparkling above a quiet Champ de Mars at night.',
    dateAdded: DateTime(2026, 6, 7),
    latitude: 48.8559,
    longitude: 2.2986,
  ),
  // Best Coffee Spots
  SavedPin(
    id: 'p5',
    name: 'Flat White Heaven',
    locationName: 'Shoreditch',
    imageUrl:
        'https://images.unsplash.com/photo-1507914372368-bc3d5a1f2614?auto=format&fit=crop&w=1200&q=80',
    collectionId: 'c2',
    description:
        'Industrial-style London café pouring the smoothest flat white.',
    dateAdded: DateTime(2026, 5, 20),
    latitude: 51.5245,
    longitude: -0.0774,
  ),
  SavedPin(
    id: 'p6',
    name: 'Window Seat Latte',
    locationName: 'Prenzlauer Berg',
    imageUrl:
        'https://images.unsplash.com/photo-1517705008128-361805f42e86?auto=format&fit=crop&w=1200&q=80',
    collectionId: 'c2',
    description:
        'Slow morning latte in a sunlit Berlin corner café with people-watching.',
    dateAdded: DateTime(2026, 5, 22),
    latitude: 52.5420,
    longitude: 13.4220,
  ),
  // Hidden Gems Istanbul
  SavedPin(
    id: 'p7',
    name: 'Golden Hour over Galata',
    locationName: 'Galata Tower',
    imageUrl:
        'https://images.unsplash.com/photo-1531875456634-3f5418280d20?auto=format&fit=crop&w=1200&q=80',
    collectionId: 'c3',
    description:
        'Skyline view of Istanbul as the sun dips behind Galata Tower.',
    dateAdded: DateTime(2026, 4, 10),
    latitude: 41.0257,
    longitude: 28.9744,
  ),
  SavedPin(
    id: 'p8',
    name: 'Balat Color Streets',
    locationName: 'Balat',
    imageUrl:
        'https://images.unsplash.com/photo-1601300651417-74be9e94d1a7?auto=format&fit=crop&w=1200&q=80',
    collectionId: 'c3',
    description:
        'Steep cobbled streets lined with pastel houses in Balat, Istanbul.',
    dateAdded: DateTime(2026, 4, 11),
    latitude: 41.0284,
    longitude: 28.9496,
  ),
];

