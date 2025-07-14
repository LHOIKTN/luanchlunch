class Recipes {
  final int id;
  final int resultId;
  final int requiredId;
  final DateTime updatedAt;

  Recipes({required this.id, required this.resultId, required this.requiredId, required this.updatedAt});

  
  Map<String, dynamic> toMap() {
    return {
      'id': id, 
      'result_id': resultId, 
      'required_id': requiredId,
      'updated_at': updatedAt,
    };
  }

  factory Recipes.fromMap(Map<String, dynamic> map) {
    return Recipes(
      id: map['id'],
      resultId: map['result_id'],
      requiredId: map['required_id'],
      updatedAt: map['updated_at'],
    );
  }

  @override
  String toString() {
    return 'Recipes(id: $id, resultId: $resultId, requiredId: $requiredId, updatedAt: $updatedAt)';
  }
}
