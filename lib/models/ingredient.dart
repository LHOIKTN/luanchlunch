import 'package:hive/hive.dart';

part 'ingredient.g.dart';

@HiveType(typeId: 1)
class Ingredient extends HiveObject {

  @HiveField(0)
  String id; // 

  @HiveField(1)
  String name; // 예: 감자
  @HiveField(2)
  String imagePath; 

  Ingredient({required this.id ,required this.name, required this.imagePath});
}
