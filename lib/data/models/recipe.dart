class Recipe {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> ingredientIds;

  Recipe({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.ingredientIds,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String,
      ingredientIds: List<String>.from(json['ingredients'] as List),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image_url': imageUrl,
        'ingredients': ingredientIds,
      };
} 