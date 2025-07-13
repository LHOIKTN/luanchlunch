import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/foods.dart';

class SqfliteHelper {
  static final SqfliteHelper instance = SqfliteHelper._internal();
  SqfliteHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_data.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE foods(
        id INTEGER PRIMARY KEY,
        name TEXT,
        image_path TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE recipes(
        id INTEGER PRIMARY KEY,
        result_id INTEGER,
        required_id INTEGER
      )
    ''');
  }

  Future<int> insertFood(int id, String name, String imagePath) async {
    final db = await database;

    final food = Food(id: id, name: name, imagePath: imagePath);
    print(food);
    return await db.insert('foods', food.toMap());
  }

  Future<List<Food>> getFoods() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('foods');
    return maps.map((e) => Food.fromMap(e)).toList();
  }

  Future<int> deleteFood(int id) async {
    final db = await database;
    return await db.delete('foods', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateFood(Food food) async {
    final db = await database;
    return await db.update(
      'foods',
      food.toMap(),
      where: 'id = ?',
      whereArgs: [food.id],
    );
  }

  Future<int> getLastFoodId() async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT id from foods ORDER BY id DESC LIMIT 1",
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    } else {
      return -1;
    }
  }

  Future<int> getLastRecipeId() async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT id from recipes ORDER BY id DESC LIMIT 1",
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    } else {
      return -1;
    }
  }
}
