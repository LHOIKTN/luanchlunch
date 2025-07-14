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

  Food({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.recipes,
    this.acquiredAt,
  });

  // Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
    };
  }

  // Create from Supabase data
  factory Food.fromSupabase(Map<String, dynamic> map) {
    return Food(
      id: map['id'],
      name: map['name'],
      imageUrl: map['image_url'],
    );
  }

  // Create copy with updated recipes
  Food copyWith({
    int? id,
    String? name,
    String? imageUrl,
    List<int>? recipes,
    DateTime? acquiredAt,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      recipes: recipes ?? this.recipes,
      acquiredAt: acquiredAt ?? this.acquiredAt,
    );
  }

  @override
  String toString() {
    return 'Food(id: $id, name: $name, imageUrl: $imageUrl, recipes: $recipes, acquiredAt: $acquiredAt)';
  }
} 