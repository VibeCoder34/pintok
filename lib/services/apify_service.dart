import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of scraping a single Instagram post via Apify.
class ApifyInstagramResult {
  const ApifyInstagramResult({
    required this.caption,
    this.locationName,
  });

  /// Full text caption of the post.
  final String caption;

  /// Optional location name extracted by the scraper (if available).
  final String? locationName;
}

/// Service for interacting with Apify's `apify/instagram-scraper` actor.
///
/// Set APIFY_API_TOKEN via:
///   --dart-define=APIFY_API_TOKEN=your_token
class ApifyService {
  ApifyService({String? apiToken}) : _apiToken = apiToken ?? _defaultApiToken;

  static const _defaultApiToken = String.fromEnvironment(
    'APIFY_API_TOKEN',
    defaultValue: '',
  );

  final String _apiToken;

  static const _runSyncUrl =
      'https://api.apify.com/v2/acts/apify~instagram-scraper/run-sync-get-dataset-items';
  static const _tiktokRunSyncUrl =
      'https://api.apify.com/v2/acts/clockworks~tiktok-scraper/run-sync-get-dataset-items';

  /// Synchronously runs the Instagram scraper for a single URL and returns
  /// the first item's caption and optional location name.
  ///
  /// Returns null on error or if no items are found.
  Future<ApifyInstagramResult?> scrapeInstagram(String url) async {
    if (_apiToken.isEmpty) {
      // Intentionally throw so misconfiguration is visible during development.
      throw StateError(
        'APIFY_API_TOKEN is not set. '
        'Run with --dart-define=APIFY_API_TOKEN=your_token',
      );
    }

    final uri = Uri.parse('$_runSyncUrl?token=$_apiToken');

    final payload = <String, dynamic>{
      'directUrls': [url],
      'resultsLimit': 1,
    };

    try {
      final response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // Apify's run-sync endpoint returns 201 Created on success.
      if (response.statusCode != 200 && response.statusCode != 201) {
        print(
          'APIFY_INSTAGRAM_ERROR: ${response.statusCode} ${response.body}',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is Map<String, dynamic>) {
          final rawCaption = first['caption'] ?? first['text'] ?? '';
          final rawLocation = first['locationName'] ?? first['placeName'];

          final caption = (rawCaption is String ? rawCaption : '$rawCaption')
              .trim();
          final locationName =
              (rawLocation is String ? rawLocation : '$rawLocation').trim();

          return ApifyInstagramResult(
            caption: caption,
            locationName: locationName.isEmpty ? null : locationName,
          );
        }
      }

      return null;
    } catch (e, stackTrace) {
      print('APIFY_INSTAGRAM_EXCEPTION: $e');
      print('APIFY_INSTAGRAM_STACK: $stackTrace');
      return null;
    }
  }

  /// Synchronously runs the TikTok scraper for a single URL and returns
  /// a caption mapped from the TikTok description field.
  ///
  /// Returns null on error or if no items are found.
  Future<ApifyInstagramResult?> scrapeTikTok(String url) async {
    if (_apiToken.isEmpty) {
      throw StateError(
        'APIFY_API_TOKEN is not set. '
        'Run with --dart-define=APIFY_API_TOKEN=your_token',
      );
    }

    final uri = Uri.parse('$_tiktokRunSyncUrl?token=$_apiToken');

    final payload = <String, dynamic>{
      'postURLs': [url],
      'resultsPerPage': 1,
      'commentsPerPost': 0,
      'shouldDownloadVideos': false,
      'shouldDownloadCovers': false,
      'shouldDownloadAvatars': false,
      'excludePinnedPosts': false,
      'scrapeRelatedVideos': false,
    };

    final jsonBody = jsonEncode(payload);
    print('TikTok Scraper Input: $jsonBody');

    try {
      final response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonBody,
      );

      final responseBody = response.body;
      print('TIKTOK_RAW_DATA: $responseBody');

      if (response.statusCode != 200 && response.statusCode != 201) {
        print(
          'APIFY_TIKTOK_ERROR: ${response.statusCode} $responseBody',
        );
        return null;
      }

      final decoded = jsonDecode(responseBody);

      if (decoded is! List || decoded.isEmpty) {
        return null;
      }

      final first = decoded.first;
      if (first is! Map<String, dynamic>) {
        return null;
      }

      // TikTok text is usually in desc; fallback to videoMeta.caption
      final videoMeta = first['videoMeta'];
      final metaMap = videoMeta is Map<String, dynamic> ? videoMeta : null;
      final rawCaption = first['desc'] ?? metaMap?['caption'] ?? first['text'] ?? first['caption'] ?? first['description'] ?? '';
      final caption = (rawCaption is String ? rawCaption : '$rawCaption').trim();

      final rawLocation =
          first['location'] ?? first['locationName'] ?? first['placeName'];
      final locationName =
          rawLocation == null || (rawLocation is String && rawLocation.trim().isEmpty)
              ? null
              : (rawLocation is String ? rawLocation : '$rawLocation').trim();

      return ApifyInstagramResult(
        caption: caption,
        locationName: locationName,
      );
    } catch (e, stackTrace) {
      print('APIFY_TIKTOK_EXCEPTION: $e');
      print('APIFY_TIKTOK_STACK: $stackTrace');
      return null;
    }
  }
}

