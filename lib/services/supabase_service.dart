import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/collection_model.dart';
import '../models/pin_model.dart';
/// Supabase-backed service for collections, pins, and profile data.
class SupabaseService {
  SupabaseService({this.overrideUserId});

  /// Optional override for the logged-in user id (mainly for tests).
  final String? overrideUserId;

  SupabaseClient get _client => Supabase.instance.client;

  String? get _currentUserId =>
      overrideUserId ?? _client.auth.currentUser?.id;

  // ---------------------------------------------------------------------------
  // Collections
  // ---------------------------------------------------------------------------

  /// Fetch all collections for the current user. Drives map filter chips and library grid.
  Future<List<CollectionModel>> getCollections() async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('No authenticated user for getCollections()');
    }

    final response = await _client
        .from('collections')
        .select('*')
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.map(CollectionModel.fromMap).toList();
  }

  /// Create a new collection for the current user.
  /// [coverColor] optional hex without # (e.g. "5E35B1") for card background when no cover image.
  Future<CollectionModel> createCollection(String name,
      {String? description, String? coverColor}) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('No authenticated user for createCollection()');
    }

    final response = await _client
        .from('collections')
        .insert(<String, dynamic>{
          'user_id': uid,
          'name': name,
          'description': description,
          'is_private': true,
          if (coverColor != null && coverColor.isNotEmpty) 'cover_color': coverColor,
        })
        .select()
        .single();

    return CollectionModel.fromMap(
        Map<String, dynamic>.from(response as Map));
  }

  /// Update a collection's name (and optionally description, visibility, cover).
  Future<CollectionModel> updateCollection(String id, String newName,
      {String? description, bool? isPrivate, String? coverImageUrl}) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('No authenticated user for updateCollection()');
    }

    final payload = <String, dynamic>{'name': newName};
    if (description != null) payload['description'] = description;
    if (isPrivate != null) payload['is_private'] = isPrivate;
    if (coverImageUrl != null) payload['cover_image_url'] = coverImageUrl;

    final response = await _client
        .from('collections')
        .update(payload)
        .eq('id', id)
        .eq('user_id', uid)
        .select()
        .single();

    return CollectionModel.fromMap(
        Map<String, dynamic>.from(response as Map));
  }

  /// Set or clear the collection cover image. Pass [imageUrl] to set, null to remove (fallback to first pin).
  Future<CollectionModel> setCollectionCover(String collectionId, String? imageUrl) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('No authenticated user for setCollectionCover()');
    }
    final response = await _client
        .from('collections')
        .update(<String, dynamic>{'cover_image_url': imageUrl})
        .eq('id', collectionId)
        .eq('user_id', uid)
        .select()
        .single();
    return CollectionModel.fromMap(Map<String, dynamic>.from(response as Map));
  }

  /// Delete a collection (pins in it are cascade-deleted by DB).
  Future<void> deleteCollection(String id) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('No authenticated user for deleteCollection()');
    }

    await _client
        .from('collections')
        .delete()
        .eq('id', id)
        .eq('user_id', uid);
  }

  // ---------------------------------------------------------------------------
  // Pins
  // ---------------------------------------------------------------------------

  /// Fetch pins for the current user. If [collectionId] is null, fetch all pins
  /// owned by the user; otherwise only pins for that collection.
  Future<List<PinModel>> getPins(String? collectionId) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('No authenticated user for getPins()');
    }

    var query = _client.from('pins').select('*');

    if (collectionId != null) {
      query = query.eq('collection_id', collectionId);
    } else {
      query = query.eq('user_id', uid);
    }

    final response = await query.order(
      'created_at',
      ascending: false,
    );
    final rows = List<Map<String, dynamic>>.from(response as List);
    return rows.map(PinModel.fromMap).toList();
  }

  /// Insert a new pin generated from Gemini analysis.
  Future<PinModel> savePin(PinModel pin) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('No authenticated user for savePin()');
    }

    final payload = <String, dynamic>{
      'collection_id': pin.collectionId,
      'user_id': uid,
      'title': pin.title,
      'description': pin.description,
      'image_url': pin.imageUrl,
      'latitude': pin.latitude,
      'longitude': pin.longitude,
      'metadata': pin.metadata ?? <String, dynamic>{},
    };

    final response =
        await _client.from('pins').insert(payload).select().single();

    return PinModel.fromMap(Map<String, dynamic>.from(response as Map));
  }

  /// Update a pin by id (e.g. title, description, collection_id).
  Future<PinModel> updatePin(String pinId, Map<String, dynamic> updates) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('No authenticated user for updatePin()');
    }

    final response = await _client
        .from('pins')
        .update(updates)
        .eq('id', pinId)
        .eq('user_id', uid)
        .select()
        .single();

    return PinModel.fromMap(Map<String, dynamic>.from(response as Map));
  }

  /// Delete a pin by id.
  Future<void> deletePin(String pinId) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('No authenticated user for deletePin()');
    }

    await _client.from('pins').delete().eq('id', pinId).eq('user_id', uid);
  }

  // ---------------------------------------------------------------------------
  // Profile & stats
  // ---------------------------------------------------------------------------

  /// Fetch the current user's profile row from public.profiles.
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final uid = _currentUserId;
    if (uid == null) return null;

    final response =
        await _client.from('profiles').select('*').eq('id', uid).limit(1);

    final rows = List<Map<String, dynamic>>.from(response as List);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Resolve display name: profile full_name, else auth user_metadata full_name, else email local part.
  String getDisplayName(Map<String, dynamic>? profileRow) {
    final fromProfile = (profileRow?['full_name'] as String?)?.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    final user = _client.auth.currentUser;
    final fromMeta = (user?.userMetadata?['full_name'] as String?)?.trim();
    if (fromMeta != null && fromMeta.isNotEmpty) return fromMeta;
    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      final part = email.split('@').first.trim();
      if (part.isNotEmpty) return part;
    }
    return 'Traveler';
  }

  /// Fetch the current user's AI scan quota from profiles.
  /// Returns safe defaults (0, null) if columns missing or query fails.
  Future<Map<String, int?>> getAiScanQuota() async {
    final uid = _currentUserId;
    if (uid == null) {
      return <String, int?>{'ai_scans_count': 0, 'ai_scans_limit': null};
    }
    try {
      final response = await _client
          .from('profiles')
          .select('ai_scans_count, ai_scans_limit')
          .eq('id', uid)
          .maybeSingle();

      if (response == null) {
        return <String, int?>{'ai_scans_count': 0, 'ai_scans_limit': null};
      }

      final map = Map<String, dynamic>.from(response as Map);
      final count = map['ai_scans_count'];
      final limit = map['ai_scans_limit'];

      return <String, int?>{
        'ai_scans_count': count is int ? count : (count is num ? count.toInt() : int.tryParse('$count') ?? 0),
        'ai_scans_limit': limit is int ? limit : (limit is num ? limit.toInt() : int.tryParse('$limit')),
      };
    } catch (_) {
      return <String, int?>{'ai_scans_count': 0, 'ai_scans_limit': null};
    }
  }

  /// Increment the current user's ai_scans_count by 1. Call after a successful AI scan (pin saved).
  Future<void> incrementAiScansCount() async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('No authenticated user for incrementAiScansCount()');
    }
    final quota = await getAiScanQuota();
    final current = quota['ai_scans_count'] ?? 0;
    await _client
        .from('profiles')
        .update(<String, dynamic>{'ai_scans_count': current + 1})
        .eq('id', uid);
  }

  /// Update the current user's profile (full_name, bio).
  Future<void> updateProfile(String fullName, String bio) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('No authenticated user for updateProfile()');
    }

    final payload = <String, dynamic>{
      'full_name': fullName,
      'bio': bio,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _client.from('profiles').update(payload).eq('id', uid);
  }

  /// Update the current user's Bitmoji avatar key (gencerkek, genckadin, yaslierkek, yaslikadin).
  Future<void> updateProfileAvatarKey(String? avatarKey) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('No authenticated user for updateProfileAvatarKey()');
    }
    await _client.from('profiles').update({
      'avatar_key': avatarKey,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', uid);
  }

  /// Wipe current user's data (pins, collections, profile). Call before signOut for Delete Account.
  Future<void> deleteUserData() async {
    await _client.rpc('delete_user_data');
  }

  /// Returns the total count of rows in the pins table for the current user.
  Future<int> getMyPinsCount() async {
    final uid = _currentUserId;
    if (uid == null) return 0;

    final response =
        await _client.from('pins').select('id').eq('user_id', uid);
    return (response as List).length;
  }

  /// Returns a map of collectionId -> number of pins in that collection
  /// for the current user. Collections with zero pins will not appear in
  /// the map.
  Future<Map<String, int>> getPinCountsByCollection() async {
    final uid = _currentUserId;
    if (uid == null) return <String, int>{};

    final response = await _client
        .from('pins')
        .select('collection_id')
        .eq('user_id', uid);

    final rows = List<Map<String, dynamic>>.from(response as List);
    final Map<String, int> counts = {};
    for (final row in rows) {
      final collectionId = row['collection_id'] as String?;
      if (collectionId == null) continue;
      counts[collectionId] = (counts[collectionId] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns a map of collectionId -> first pin imageUrl (by created_at ASC)
  /// for the current user. Only pins with a non-empty image_url are used.
  Future<Map<String, String>> getFirstPinImageByCollection() async {
    final uid = _currentUserId;
    if (uid == null) return <String, String>{};

    final response = await _client
        .from('pins')
        .select('collection_id,image_url,created_at')
        .eq('user_id', uid)
        .order('created_at', ascending: true);

    final rows = List<Map<String, dynamic>>.from(response as List);
    final Map<String, String> coverImages = {};

    for (final row in rows) {
      final collectionId = row['collection_id'] as String?;
      final imageUrl = row['image_url'] as String?;
      if (collectionId == null || imageUrl == null || imageUrl.isEmpty) {
        continue;
      }
      // Only take the first image per collection (oldest pin wins).
      coverImages.putIfAbsent(collectionId, () => imageUrl);
    }

    return coverImages;
  }

  /// Returns the total count of rows in the collections table for the current user.
  Future<int> getMyCollectionsCount() async {
    final uid = _currentUserId;
    if (uid == null) return 0;

    final response =
        await _client.from('collections').select('id').eq('user_id', uid);
    return (response as List).length;
  }
}
