import 'package:launchlunch/data/supabase/api_service.dart';
import 'package:launchlunch/data/supabase/supabase_client.dart';
import 'package:launchlunch/data/sqflite/sqflite_helper.dart';
import 'package:launchlunch/data/sqflite/recipe_helper.dart';
import 'package:intl/intl.dart';
import 'package:launchlunch/utils/download_image.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:launchlunch/screens/inventory.dart';

Future<void> syncInitialData() async {
  await SqfliteHelper.instance.database;
  await initSupabase();

  final supabase = SupabaseApi();
  // await syncFoodData(supabase);rRRR
  await syncRecipes(supabase);
}

Future<void> syncFoodData(SupabaseApi supabase) async {
  try {
    final lastFoodId = await SqfliteHelper.instance.getLastFoodId();
    final foods = await supabase.getFoodDatas(lastFoodId);
    if (foods.isEmpty) return;
    for (final food in foods) {
      final id = food['id'];
      final name = food['name'];
      final imageUrl = food['image_url'];
      final savedPath = await downloadAndSaveImage(imageUrl);
      if (savedPath == null) continue;
      await SqfliteHelper.instance.insertFood(id, name, savedPath);
    }
  } catch (e) {
    return;
  }
}

Future<void> syncRecipes(SupabaseApi api) async {
  final latestUpdatedAt = await RecipeHelper.instance.getLatestRecipeUpdatedAt();
  print('latestUpdatedAt: $latestUpdatedAt');
  final recipes = await api.getRecipes(latestUpdatedAt);
  print('recipes: $recipes');
  if (recipes.isEmpty) return;
  for (final recipe in recipes) {
    final id = recipe['id'];
    final resultId = recipe['result_id'];
    final requiredId = recipe['required_id'];
    final updatedAt = DateTime.parse(recipe['updated_at']);
    print('Recipe(id:$id, resultId:$resultId, requiredId:$requiredId, updatedAt:$updatedAt)');
    await RecipeHelper.instance.upsertRecipe(id, resultId, requiredId, updatedAt);
  }
}

Future<void> syncInventory(SupabaseApi api) async {}

Future<void> syncTodayMeal(SupabaseApi api) async {}
