class CollectionModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final DateTime createdAt;
  /// When true, only the owner sees this collection; when false, visible on profile.
  final bool isPrivate;
  /// Optional cover image URL. When null/empty, UI uses first pin image or coverColor.
  final String? coverImageUrl;
  /// Hex color (e.g. "5E35B1") for card background when no cover image. From create flow.
  final String? coverColor;

  const CollectionModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.createdAt,
    this.isPrivate = true,
    this.coverImageUrl,
    this.coverColor,
  });

  /// Factory using a generic Map (e.g. Supabase row).
  factory CollectionModel.fromMap(Map<String, dynamic> map) {
    return CollectionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isPrivate: map['is_private'] == null ? true : (map['is_private'] as bool),
      coverImageUrl: map['cover_image_url'] as String?,
      coverColor: map['cover_color'] as String?,
    );
  }

  /// Backwards-compatible alias when something expects `fromJson`.
  factory CollectionModel.fromJson(Map<String, dynamic> json) =>
      CollectionModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'is_private': isPrivate,
      'cover_image_url': coverImageUrl,
      'cover_color': coverColor,
    };
  }
}

