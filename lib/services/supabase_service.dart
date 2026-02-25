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
  Future<CollectionModel> createCollection(String name,
      {String? description}) async {
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
        })
        .select()
        .single();

    return CollectionModel.fromMap(
        Map<String, dynamic>.from(response as Map));
  }

  /// Update a collection's name (and optionally description).
  Future<CollectionModel> updateCollection(String id, String newName,
      {String? description}) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('No authenticated user for updateCollection()');
    }

    final payload = <String, dynamic>{'name': newName};
    if (description != null) payload['description'] = description;

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

    final response = await _client
        .from('profiles')
        .select('*')
        .eq('id', uid)
        .limit(1);

    final rows = List<Map<String, dynamic>>.from(response as List);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Update the current user's profile (full_name, bio, optional username).
  Future<void> updateProfile(String fullName, String bio,
      {String? username}) async {
    final uid = _currentUserId;
    if (uid == null) {
      throw StateError('No authenticated user for updateProfile()');
    }

    final payload = <String, dynamic>{
      'full_name': fullName,
      'bio': bio,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (username != null) payload['username'] = username;

    await _client.from('profiles').update(payload).eq('id', uid);
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
