import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;
  static const int _currentVersion = 2; // Increment version for migration

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_data.db');

    return await openDatabase(
      path, 
      version: _currentVersion, 
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create foods table
    await db.execute('''
      CREATE TABLE foods(
        id INTEGER PRIMARY KEY,
        name TEXT,
        image_path TEXT
      )
    ''');

    // Create recipes table with updated_at column
    await db.execute('''
      CREATE TABLE recipes(
        id INTEGER PRIMARY KEY,
        result_id INTEGER,
        required_id INTEGER,
        updated_at TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add updated_at column to existing recipes table
      try {
        await db.execute('ALTER TABLE recipes ADD COLUMN updated_at TEXT');
        print('✅ Added updated_at column to recipes table');
      } catch (e) {
        print('⚠️ Column updated_at might already exist: $e');
      }
    }
  }
} 