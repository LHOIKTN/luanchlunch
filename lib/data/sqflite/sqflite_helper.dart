import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/foods.dart';
import '../../models/recipes.dart';
import 'database_helper.dart';
import 'food_helper.dart';
import 'recipe_helper.dart';

class SqfliteHelper {
  static final SqfliteHelper instance = SqfliteHelper._internal();
  SqfliteHelper._internal();

  // Database instance
  Future<Database> get database async {
    return await DatabaseHelper.instance.database;
  }

  // Food operations - delegate to FoodHelper
  Future<int> insertFood(int id, String name, String imagePath) async {
    return await FoodHelper.instance.insertFood(id, name, imagePath);
  }

  Future<List<Food>> getFoods() async {
    return await FoodHelper.instance.getFoods();
  }

  Future<int> deleteFood(int id) async {
    return await FoodHelper.instance.deleteFood(id);
  }

  Future<int> updateFood(Food food) async {
    return await FoodHelper.instance.updateFood(food);
  }

  Future<int> getLastFoodId() async {
    return await FoodHelper.instance.getLastFoodId();
  }

  // Recipe operations - delegate to RecipeHelper
  Future<int> upsertRecipe(int id, int resultId, int requiredId, DateTime updatedAt) async {
    return await RecipeHelper.instance.upsertRecipe(id, resultId, requiredId, updatedAt);
  }

  Future<int> insertRecipe(int id, int resultId, int requiredId, String updatedAt) async {
    return await RecipeHelper.instance.insertRecipe(id, resultId, requiredId, updatedAt);
  }

  Future<int> getLastRecipeId() async {
    return await RecipeHelper.instance.getLastRecipeId();
  }

  Future<String> getLatestRecipeUpdatedAt() async {
    return await RecipeHelper.instance.getLatestRecipeUpdatedAt();
  }

  Future<Map<int, List<int>>> getRecipesForInventory() async {
    return await RecipeHelper.instance.getRecipesForInventory();
  }

  Future<bool> canMakeRecipe(int resultId, List<int> userInventory) async {
    return await RecipeHelper.instance.canMakeRecipe(resultId, userInventory);
  }

  Future<List<int>> getAvailableRecipes(List<int> userInventory) async {
    return await RecipeHelper.instance.getAvailableRecipes(userInventory);
  }
}
