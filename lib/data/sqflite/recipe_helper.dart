import 'package:sqflite/sqflite.dart';
import '../../models/recipes.dart';
import 'database_helper.dart';

class RecipeHelper {
  static final RecipeHelper instance = RecipeHelper._internal();
  RecipeHelper._internal();

  Future<int> upsertRecipe(int id, int resultId, int requiredId, DateTime updatedAt) async {
    final db = await DatabaseHelper.instance.database;
    final recipe = Recipes(id: id, resultId: resultId, requiredId: requiredId, updatedAt: updatedAt);
    
    // Check if recipe with this ID already exists
    final existingRecipes = await db.query(
      'recipes',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (existingRecipes.isNotEmpty) {
      // Update existing recipe
      return await db.update(
        'recipes',
        recipe.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      // Insert new recipe
      return await db.insert('recipes', recipe.toMap());
    }
  }

  // Keep the original method for backward compatibility
  Future<int> insertRecipe(int id, int resultId, int requiredId, String updatedAt) async {
    final db = await DatabaseHelper.instance.database;
    final recipe = Recipes(
      id: id, 
      resultId: resultId, 
      requiredId: requiredId, 
      updatedAt: DateTime.parse(updatedAt)
    );
    return await db.insert('recipes', recipe.toMap());
  }

  Future<int> getLastRecipeId() async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT id from recipes ORDER BY id DESC LIMIT 1",
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    } else {
      return -1;
    }
  }

  Future<String> getLatestRecipeUpdatedAt() async {
    final db = await DatabaseHelper.instance.database;

    try {
      final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT MAX(updated_at) AS latest FROM recipes',
      );
      String latestUpdatedAt = result.first['latest'] ?? '1970-01-01';
      return latestUpdatedAt;
    } catch (e) {
      print('⚠️ Error getting latest recipe updated_at: $e');
      print('⚠️ Returning default date: 1970-01-01');
      return '1970-01-01';
    }
  }

  // Get recipes in resultId:[required_id] format for inventory screen
  Future<Map<int, List<int>>> getRecipesForInventory() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('recipes');
    
    final Map<int, List<int>> recipeMap = {};
    
    for (final map in maps) {
      final resultId = map['result_id'] as int;
      final requiredId = map['required_id'] as int;
      
      if (recipeMap.containsKey(resultId)) {
        recipeMap[resultId]!.add(requiredId);
      } else {
        recipeMap[resultId] = [requiredId];
      }
    }
    
    return recipeMap;
  }

  // Check if user has ingredients for a specific recipe
  Future<bool> canMakeRecipe(int resultId, List<int> userInventory) async {
    final recipeMap = await getRecipesForInventory();
    final requiredIds = recipeMap[resultId];
    
    if (requiredIds == null) return false;
    
    // Check if user has all required ingredients
    for (final requiredId in requiredIds) {
      if (!userInventory.contains(requiredId)) {
        return false;
      }
    }
    
    return true;
  }

  // Get all recipes that user can make with current inventory
  Future<List<int>> getAvailableRecipes(List<int> userInventory) async {
    final recipeMap = await getRecipesForInventory();
    final List<int> availableRecipes = [];
    
    for (final entry in recipeMap.entries) {
      final resultId = entry.key;
      final requiredIds = entry.value;
      
      bool canMake = true;
      for (final requiredId in requiredIds) {
        if (!userInventory.contains(requiredId)) {
          canMake = false;
          break;
        }
      }
      
      if (canMake) {
        availableRecipes.add(resultId);
      }
    }
    
    return availableRecipes;
  }
} 