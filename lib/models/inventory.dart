class Inventory {
  final int foodId;
  final DateTime acquiredAt;

  Inventory({required this.foodId, required this.acquiredAt});

  Map<String, dynamic> toMap() {
    return {
      'food_id': foodId,
      'acquired_at': acquiredAt.toIso8601String(),
    };
  }

  factory Inventory.fromMap(Map<String, dynamic> map) {
    return Inventory(
      foodId: map['food_id'],
      acquiredAt: DateTime.parse(map['acquired_at']),
    );
  }

  @override
  String toString() {
    return 'Inventory(foodId: $foodId, acquiredAt: $acquiredAt)';
  }
}
