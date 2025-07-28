import 'package:hive/hive.dart';

part 'food.g.dart';

@HiveType(typeId: 0)
class Food extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String imageUrl;

  @HiveField(3)
  final List<int>? recipes; // required_id list for this food

  @HiveField(4)
  final DateTime? acquiredAt; // when user acquired this food

  @HiveField(5)
  final String? detail; // detailed description from Supabase

  Food({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.recipes,
    this.acquiredAt,
    this.detail,
  });

  // Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'detail': detail,
    };
  }

  // Create from Supabase data
  factory Food.fromSupabase(Map<String, dynamic> map) {
    return Food(
      id: map['id'],
      name: map['name'],
      imageUrl: map['image_url'],
      detail: map['detail'],
    );
  }

  // Create copy with updated recipes
  Food copyWith({
    int? id,
    String? name,
    String? imageUrl,
    List<int>? recipes,
    DateTime? acquiredAt,
    String? detail,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      recipes: recipes ?? this.recipes,
      acquiredAt: acquiredAt ?? this.acquiredAt,
      detail: detail ?? this.detail,
    );
  }

  @override
  String toString() {
    return 'Food(id: $id, name: $name, imageUrl: $imageUrl, recipes: $recipes, acquiredAt: $acquiredAt, detail: $detail)';
  }
} 