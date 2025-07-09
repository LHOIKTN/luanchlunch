class Ingredient {
  final String id;
  final String name;
  final String imageUrl;

  Ingredient({required this.id, required this.name, required this.imageUrl});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image_url': imageUrl,
      };
} 