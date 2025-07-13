class Food {
  final int id;
  final String name;
  final String imagePath;

  Food({required this.id, required this.name, required this.imagePath});

  Map<String, dynamic> toMap() {
    return {
      'id': id, // DB에 자동 증가 맡기는 경우
      'name': name,
      'image_path': imagePath, // DB 컬럼명은 snake_case
    };
  }

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['id'],
      name: map['name'],
      imagePath: map['image_path'], // DB -> 객체 변환 시 mapping
    );
  }

  @override
  String toString() {
    return 'Food(id: $id, name: $name, imagePath: $imagePath)';
  }
}
