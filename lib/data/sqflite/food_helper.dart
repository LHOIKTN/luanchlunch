import 'package:sqflite/sqflite.dart';
import '../../models/foods.dart';
import 'database_helper.dart';

class FoodHelper {
  static final FoodHelper instance = FoodHelper._internal();
  FoodHelper._internal();

  Future<int> insertFood(int id, String name, String imagePath) async {
    final db = await DatabaseHelper.instance.database;
    final food = Food(id: id, name: name, imagePath: imagePath);
    print(food);
    return await db.insert('foods', food.toMap());
  }

  Future<List<Food>> getFoods() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('foods');
    return maps.map((e) => Food.fromMap(e)).toList();
  }

  Future<int> deleteFood(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete('foods', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateFood(Food food) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'foods',
      food.toMap(),
      where: 'id = ?',
      whereArgs: [food.id],
    );
  }

  Future<int> getLastFoodId() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT id from foods ORDER BY id DESC LIMIT 1",
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    } else {
      return -1;
    }
  }
} 