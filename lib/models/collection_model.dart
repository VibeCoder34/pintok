class CollectionModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final DateTime createdAt;

  const CollectionModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  /// Factory using a generic Map (e.g. Supabase row).
  factory CollectionModel.fromMap(Map<String, dynamic> map) {
    return CollectionModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
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
    };
  }
}

