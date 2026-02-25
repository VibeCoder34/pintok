import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service for Google Places API (New): Text Search and Place Photos.
/// Set GOOGLE_PLACES_API_KEY via --dart-define=GOOGLE_PLACES_API_KEY=your_key when running.
class GooglePlacesService {
  GooglePlacesService({String? apiKey}) : _apiKey = apiKey ?? _defaultApiKey;

  static const _defaultApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: '',
  );

  final String _apiKey;

  static const _textSearchUrl = 'https://places.googleapis.com/v1/places:searchText';
  static const _maxPhotoWidthPx = 1200;

  /// Searches for a place by name and coordinates using Text Search (New),
  /// then returns a high-resolution photo URL from the first result's first photo.
  /// Returns null if the key is missing, no place is found, or the place has no photos.
  Future<String?> getPlacePhoto(String placeName, double lat, double lng) async {
    if (_apiKey.isEmpty) {
      return null;
    }

    try {
      final photoName = await _searchPlacePhotoName(placeName, lat, lng);
      if (photoName == null || photoName.isEmpty) return null;

      final photoUri = await _getPhotoMediaUri(photoName);
      return photoUri;
    } catch (e, st) {
      print('GooglePlacesService.getPlacePhoto: $e');
      print(st);
      return null;
    }
  }

  /// Text Search (New): find place by query and location bias, return first photo name.
  Future<String?> _searchPlacePhotoName(String placeName, double lat, double lng) async {
    final uri = Uri.parse(_textSearchUrl);
    final body = jsonEncode(<String, dynamic>{
      'textQuery': placeName,
      'locationBias': <String, dynamic>{
        'circle': <String, dynamic>{
          'center': <String, dynamic>{
            'latitude': lat,
            'longitude': lng,
          },
          'radius': 500.0,
        },
      },
    });

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': _apiKey,
        'X-Goog-FieldMask': 'places.id,places.photos',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      print('GooglePlacesService Text Search: ${response.statusCode} ${response.body}');
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final places = data['places'] as List<dynamic>?;
    if (places == null || places.isEmpty) return null;

    final firstPlace = places.first as Map<String, dynamic>;
    final photos = firstPlace['photos'] as List<dynamic>?;
    if (photos == null || photos.isEmpty) return null;

    final firstPhoto = photos.first as Map<String, dynamic>;
    final name = firstPhoto['name'] as String?;
    return name;
  }

  /// Place Photos (New): get media URI for a photo name (skipHttpRedirect to get JSON with photoUri).
  Future<String?> _getPhotoMediaUri(String photoName) async {
    // photoName is like "places/ChIJ.../photos/..."
    final path = photoName.startsWith('places/') ? photoName : 'places/$photoName';
    final uri = Uri.parse(
      'https://places.googleapis.com/v1/$path/media'
      '?maxWidthPx=$_maxPhotoWidthPx&key=$_apiKey&skipHttpRedirect=true',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      print('GooglePlacesService getMedia: ${response.statusCode} ${response.body}');
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final photoUri = data['photoUri'] as String?;
    if (photoUri == null || photoUri.isEmpty) return null;

    // photoUri may be protocol-relative (//lh3.googleusercontent.com/...); make absolute
    if (photoUri.startsWith('//')) {
      return 'https:$photoUri';
    }
    return photoUri;
  }
}
