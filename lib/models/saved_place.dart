import 'dart:typed_data';

import '../services/ai_service.dart';
import 'mock_location.dart';

/// A place saved by the user: location, AI analysis, and optional original photo.
class SavedPlace {
  const SavedPlace({
    required this.location,
    required this.spot,
    this.imageBytes,
    this.collectionId,
  });

  final MockLocation location;
  final AnalyzedSpot spot;
  /// Original uploaded photo bytes for the archive card.
  final Uint8List? imageBytes;
  /// Optional ID of the collection this pin belongs to (for profile/My Journey).
  final String? collectionId;

  String get id => location.id;
  String get name => location.name;
  String get city => spot.city;
  String? get category => spot.category;
  String get description => spot.description;

  /// Tags for filter/search: e.g. #Paris #Architecture #Cafe
  List<String> get tags {
    final list = <String>[];
    if (city.isNotEmpty) list.add(city);
    if (category != null && category!.isNotEmpty) list.add(category!);
    return list;
  }
}
