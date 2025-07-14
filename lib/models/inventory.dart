class Inventory {
  final int foodId;
  final DateTime acquiredAt;

  Inventory({required this.foodId, required this.acquiredAt});

  Map<String, dynamic> toMap() {
    return {
      'food_id': foodId, // DB에 자동 증가 맡기는 경우
      'acquired_at': acquiredAt, // DB 컬럼명은 snake_case
    };
  }

  factory Inventory.fromMap(Map<String, dynamic> map) {
    return Inventory(foodId: map['food_id'], acquiredAt: map['acquired_at']);
  }

  @override
  String toString() {
    return 'Inventory(foodId: $foodId,  acquired_at: $acquiredAt)';
  }
}
