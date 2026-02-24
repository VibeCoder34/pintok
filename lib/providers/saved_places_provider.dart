import 'package:flutter/foundation.dart';

import '../models/saved_place.dart';
import '../models/mock_location.dart';

/// Single source of truth for user's saved places. Syncs with Map and Saved screens.
class SavedPlacesProvider extends ChangeNotifier {
  final List<SavedPlace> _places = [];

  List<SavedPlace> get places => List.unmodifiable(_places);

  /// Locations only (for map pins and carousel).
  List<MockLocation> get locations => _places.map((p) => p.location).toList();

  void add(SavedPlace place) {
    if (_places.any((p) => p.id == place.id)) return;
    _places.add(place);
    notifyListeners();
  }

  void remove(SavedPlace place) {
    _places.removeWhere((p) => p.id == place.id);
    notifyListeners();
  }

  void removeById(String id) {
    _places.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  SavedPlace? byId(String id) {
    try {
      return _places.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
