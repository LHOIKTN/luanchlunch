import 'package:hive/hive.dart';
import 'package:launchlunch/models/ingredient.dart';
part 'daily_data.g.dart';

@HiveType(typeId: 0)
class DailyData extends HiveObject {
  @HiveField(0)
  String date;

  @HiveField(1)
  List<String> menuText;

  @HiveField(2)
  List<Ingredient> ingredients;

  DailyData({
    required this.date,
    required this.menuText,
    required this.ingredients,
  });
}
