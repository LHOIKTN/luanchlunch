class Recipes {
  final int id;
  final int resultId;
  final int requiredId;

  Recipes({required this.id, required this.resultId, required this.requiredId});

  Map<String, dynamic> toMap() {
    return {'id': id, 'result_id': resultId, 'required_id': requiredId};
  }

  factory Recipes.fromMap(Map<String, dynamic> map) {
    return Recipes(
      id: map['id'],
      resultId: map['result_id'],
      requiredId: map['required_id'],
    );
  }

  @override
  String toString() {
    return 'Recipes(id: $id, resultId: $resultId, requiredId: $requiredId)';
  }
}
