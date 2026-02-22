import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mock_location.dart';

/// Result of AI image analysis: place name, city, and description.
class AnalyzedSpot {
  const AnalyzedSpot({
    required this.name,
    required this.city,
    required this.description,
  });

  final String name;
  final String city;
  final String description;

  factory AnalyzedSpot.fromJson(Map<String, dynamic> json) {
    return AnalyzedSpot(
      name: (json['name'] as String?)?.trim() ?? '',
      city: (json['city'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
    );
  }
}

/// System prompt for the travel assistant: extract place, city, description as JSON.
const _systemPrompt = r'''
You are a travel assistant. Look at this social media screenshot and extract the exact name of the place, the city, and a short 1-sentence description. If you can't find a specific place, guess based on visual cues. Return ONLY a JSON object: {"name": "...", "city": "...", "description": "..."}.
''';

/// Service for Gemini image analysis and geocoding.
/// Set GEMINI_API_KEY via --dart-define=GEMINI_API_KEY=your_key when running.
class AiService {
  AiService({String? apiKey}) : _apiKey = apiKey ?? _defaultApiKey;

  static const _defaultApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  final String _apiKey;

  /// Analyzes an image with Gemini 3.1 Pro Preview and returns [AnalyzedSpot] or null on failure.
  /// [imageFile] can be [XFile] (from image_picker) or any object with [readAsBytes()].
  /// For [XFile], mime type is inferred (e.g. image/jpeg, image/png).
  Future<AnalyzedSpot?> analyzeImage(dynamic imageFile) async {
    try {
      if (_apiKey.isEmpty) {
        throw StateError(
          'GEMINI_API_KEY is not set. Run with --dart-define=GEMINI_API_KEY=your_key',
        );
      }

      final bytes = await imageFile.readAsBytes();
      final mimeType = await _getMimeType(imageFile);
      final text = await _generateContentWithHttp(
        imageBytes: bytes,
        mimeType: mimeType,
        prompt: _systemPrompt,
      );
      print('GEMINI_RAW_RESPONSE: ${text ?? "(null or empty)"}');
      if (text == null || text.isEmpty) return null;

      final jsonStr = _extractJson(text);
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final spot = AnalyzedSpot.fromJson(map);
      if (spot.name.isEmpty && spot.city.isEmpty) return null;
      return spot;
    } catch (e, stackTrace) {
      print('GEMINI_ERROR: $e');
      print('GEMINI_ERROR_STACK: $stackTrace');
      return null;
    }
  }

  /// Temporary connectivity test for project/API validation.
  /// Sends a text-only prompt ("Hi") to gemini-3.1-pro-preview.
  /// If this returns 404 too, the issue is likely project/API setup, not image payload.
  Future<String?> testTextOnlyConnectivity() async {
    try {
      if (_apiKey.isEmpty) {
        throw StateError(
          'GEMINI_API_KEY is not set. Run with --dart-define=GEMINI_API_KEY=your_key',
        );
      }

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-pro-preview:generateContent?key=$_apiKey',
      );

      final body = <String, dynamic>{
        'contents': [
          {
            'parts': [
              {'text': 'Hi'},
            ],
          },
        ],
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('GEMINI_TEXT_TEST_STATUS: ${response.statusCode}');
      print('GEMINI_TEXT_TEST_BODY: ${response.body}');

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;

      final candidate = candidates.first as Map<String, dynamic>;
      final content = candidate['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return null;

      for (final part in parts) {
        if (part is Map<String, dynamic>) {
          final text = part['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            return text.trim();
          }
        }
      }
      return null;
    } catch (e, stackTrace) {
      print('GEMINI_TEXT_TEST_ERROR: $e');
      print('GEMINI_TEXT_TEST_STACK: $stackTrace');
      return null;
    }
  }

  /// Temporary debug helper: lists models accessible by current API key.
  Future<void> listAvailableModels() async {
    try {
      if (_apiKey.isEmpty) {
        throw StateError(
          'GEMINI_API_KEY is not set. Run with --dart-define=GEMINI_API_KEY=your_key',
        );
      }

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey',
      );
      final response = await http.get(url);
      print('AVAILABLE_MODELS_STATUS: ${response.statusCode}');
      print('AVAILABLE_MODELS: ${response.body}');
    } catch (e, stackTrace) {
      print('AVAILABLE_MODELS_ERROR: $e');
      print('AVAILABLE_MODELS_STACK: $stackTrace');
    }
  }

  /// Calls Gemini generateContent via HTTP using a multimodal request body.
  Future<String?> _generateContentWithHttp({
    required List<int> imageBytes,
    required String mimeType,
    required String prompt,
  }) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-pro-preview:generateContent?key=$_apiKey',
    );

    final body = <String, dynamic>{
      'contents': [
        {
          'parts': [
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Encode(imageBytes),
              },
            },
            {'text': prompt},
          ],
        },
      ],
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      print('GEMINI_HTTP_ERROR (${url.path}): ${response.statusCode} ${response.body}');
      return null;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return null;

    final candidate = candidates.first as Map<String, dynamic>;
    final content = candidate['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return null;

    for (final part in parts) {
      if (part is Map<String, dynamic>) {
        final text = part['text'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
    }

    return null;
  }

  static Future<String> _getMimeType(dynamic imageFile) async {
    try {
      final mime = imageFile.mimeType;
      if (mime != null && mime.toString().isNotEmpty) return mime.toString();
    } catch (_) {}
    return 'image/jpeg';
  }

  /// Tries to extract a JSON object from model output (may be wrapped in markdown).
  static String _extractJson(String text) {
    String cleaned = text.trim();
    final codeBlockStart = '```json';
    final codeBlockEnd = '```';
    if (cleaned.contains(codeBlockStart)) {
      final start = cleaned.indexOf(codeBlockStart) + codeBlockStart.length;
      final end = cleaned.indexOf(codeBlockEnd, start);
      if (end > start) cleaned = cleaned.substring(start, end).trim();
    } else if (cleaned.contains(codeBlockEnd)) {
      final end = cleaned.indexOf(codeBlockEnd);
      cleaned = cleaned.substring(0, end).trim();
    }
    return cleaned;
  }

  /// Resolves [AnalyzedSpot] to coordinates using Nominatim (OpenStreetMap).
  /// Returns a [MockLocation] or null if geocoding fails.
  static Future<MockLocation?> geocode(AnalyzedSpot spot) async {
    final query = Uri.encodeComponent('${spot.name}, ${spot.city}');
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'PinTok/1.0'},
      );
      if (response.statusCode != 200) return null;

      final list = json.decode(response.body) as List<dynamic>;
      if (list.isEmpty) return null;

      final item = list.first as Map<String, dynamic>;
      final lat = double.tryParse('${item['lat']}');
      final lng = double.tryParse('${item['lon']}');
      if (lat == null || lng == null) return null;

      final id = 'ai_${spot.name.hashCode}_${spot.city.hashCode}'.replaceAll('-', 'm');
      return MockLocation(
        id: id,
        name: spot.name,
        city: spot.city,
        lat: lat,
        lng: lng,
        thumbnailColor: null,
      );
    } catch (_) {
      return null;
    }
  }
}
