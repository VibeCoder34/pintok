import 'dart:ui';

import 'package:flutter/material.dart';

/// Model for a discoverable/pinnable location (map & carousel).
class MockLocation {
  const MockLocation({
    required this.id,
    required this.name,
    required this.city,
    required this.lat,
    required this.lng,
    this.imageUrl,
    this.thumbnailColor,
  });

  final String id;
  final String name;
  final String city;
  final double lat;
  final double lng;
  final String? imageUrl;
  /// Fallback color when no image (for pin placeholder).
  final Color? thumbnailColor;

  /// Normalized position for placeholder map (0–1). Used to position pins.
  Offset get normalizedPosition => Offset(
        (lng + 180) / 360,
        (90 - lat) / 180,
      );
}

/// Paris discovery list for the map carousel.
final List<MockLocation> mockDiscoverLocations = [
  const MockLocation(
    id: 'eiffel',
    name: 'Eiffel Tower',
    city: 'Paris',
    lat: 48.8584,
    lng: 2.2945,
    thumbnailColor: Color(0xFF4A90A4),
  ),
  const MockLocation(
    id: 'louvre',
    name: 'Louvre',
    city: 'Paris',
    lat: 48.8606,
    lng: 2.3376,
    thumbnailColor: Color(0xFF8B7355),
  ),
  const MockLocation(
    id: 'pink_mamma',
    name: 'Pink Mamma',
    city: 'Paris',
    lat: 48.8628,
    lng: 2.3444,
    thumbnailColor: Color(0xFFFFB6C1),
  ),
  const MockLocation(
    id: 'notre_dame',
    name: 'Notre-Dame',
    city: 'Paris',
    lat: 48.8530,
    lng: 2.3499,
    thumbnailColor: Color(0xFF6B6B6B),
  ),
  const MockLocation(
    id: 'sacré_coeur',
    name: 'Sacré-Cœur',
    city: 'Paris',
    lat: 48.8867,
    lng: 2.3431,
    thumbnailColor: Color(0xFFE8E4D9),
  ),
];
