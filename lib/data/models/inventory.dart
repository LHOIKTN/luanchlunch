class InventoryItem {
  final String id;
  final String ingredientId;
  final DateTime acquiredAt;

  InventoryItem({
    required this.id,
    required this.ingredientId,
    required this.acquiredAt,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      ingredientId: json['ingredient_id'] as String,
      acquiredAt: DateTime.parse(json['acquired_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingredient_id': ingredientId,
        'acquired_at': acquiredAt.toIso8601String(),
      };
} 