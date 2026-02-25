class PinModel {
  final String id;
  final String collectionId;
  final String userId;
  final String title;
  final String? description;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const PinModel({
    required this.id,
    required this.collectionId,
    required this.userId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.metadata,
    required this.createdAt,
  });

  /// Convenience constructor for creating a pin to insert.
  /// `id`, `userId`, and `createdAt` will be supplied by Supabase.
  PinModel.forInsert({
    required String collectionId,
    required String title,
    String? description,
    String? imageUrl,
    required double latitude,
    required double longitude,
    Map<String, dynamic>? metadata,
  }) : this(
          id: '',
          collectionId: collectionId,
          userId: '',
          title: title,
          description: description,
          imageUrl: imageUrl,
          latitude: latitude,
          longitude: longitude,
          metadata: metadata,
          createdAt: DateTime.now().toUtc(),
        );

  /// Factory using a generic Map (e.g. Supabase row).
  factory PinModel.fromMap(Map<String, dynamic> map) {
    return PinModel(
      id: map['id'] as String,
      collectionId: map['collection_id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Backwards-compatible alias when something expects `fromJson`.
  factory PinModel.fromJson(Map<String, dynamic> json) =>
      PinModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'collection_id': collectionId,
      'user_id': userId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

