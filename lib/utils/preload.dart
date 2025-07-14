import 'package:launchlunch/data/supabase/api_service.dart';
import 'package:launchlunch/data/supabase/supabase_client.dart';
import 'package:launchlunch/data/hive/hive_helper.dart';
import 'package:launchlunch/models/food.dart';

Future<void> syncInitialData() async {
  await HiveHelper.instance.init();
  await initSupabase();

  final supabase = SupabaseApi();
  await syncFoodData(supabase);
  await syncRecipes(supabase);
  await syncInventory(supabase);
}

Future<void> syncFoodData(SupabaseApi supabase) async {
  try {
    final lastUpdatedAt = HiveHelper.instance.getLastUpdatedAt('foods');
    print('🔄 Syncing foods since: $lastUpdatedAt');
    
    final foods = await supabase.getFoodDatas(lastUpdatedAt);
    if (foods.isEmpty) {
      print('✅ No new foods to sync');
      return;
    }
    
    final List<Food> foodList = [];
    String latestUpdatedAt = lastUpdatedAt;
    
    for (final foodData in foods) {
      final food = Food.fromSupabase(foodData);
      foodList.add(food);
      
      // Track the latest updated_at
      if (foodData['updated_at'] != null) {
        final updatedAt = foodData['updated_at'];
        if (updatedAt.compareTo(latestUpdatedAt) > 0) {
          latestUpdatedAt = updatedAt;
        }
      }
    }
    
    await HiveHelper.instance.saveFoods(foodList);
    await HiveHelper.instance.setLastUpdatedAt('foods', latestUpdatedAt);
    
    print('✅ Synced ${foodList.length} foods from Supabase');
    print('📅 Updated last sync time to: $latestUpdatedAt');
  } catch (e) {
    print('❌ Error syncing food data: $e');
  }
}

Future<void> syncRecipes(SupabaseApi api) async {
  try {
    final lastUpdatedAt = HiveHelper.instance.getLastUpdatedAt('recipes');
    print('🔄 Syncing recipes since: $lastUpdatedAt');
    
    final recipes = await api.getRecipes(lastUpdatedAt);
    if (recipes.isEmpty) {
      print('✅ No new recipes to sync');
      return;
    }
    
    // Group recipes by result_id
    final Map<int, List<int>> recipeMap = {};
    String latestUpdatedAt = lastUpdatedAt;
    
    for (final recipe in recipes) {
      final resultId = recipe['result_id'];
      final requiredId = recipe['required_id'];
      
      if (recipeMap.containsKey(resultId)) {
        recipeMap[resultId]!.add(requiredId);
      } else {
        recipeMap[resultId] = [requiredId];
      }
      
      // Track the latest updated_at
      if (recipe['updated_at'] != null) {
        final updatedAt = recipe['updated_at'];
        if (updatedAt.compareTo(latestUpdatedAt) > 0) {
          latestUpdatedAt = updatedAt;
        }
      }
    }
    
    // Update foods with their recipes
    for (final entry in recipeMap.entries) {
      final resultId = entry.key;
      final requiredIds = entry.value;
      
      await HiveHelper.instance.updateFoodRecipes(resultId, requiredIds);
      print('📝 Updated food $resultId with recipes: $requiredIds');
    }
    
    await HiveHelper.instance.setLastUpdatedAt('recipes', latestUpdatedAt);
    
    print('✅ Synced ${recipeMap.length} recipe mappings');
    print('📅 Updated last sync time to: $latestUpdatedAt');
  } catch (e) {
    print('❌ Error syncing recipes: $e');
  }
}

Future<void> syncInventory(SupabaseApi api) async {
  try {
    final lastUpdatedAt = HiveHelper.instance.getLastUpdatedAt('inventory');
    print('🔄 Syncing inventory since: $lastUpdatedAt');
    
    // Get user's inventory from Supabase
    final inventory = await api.getInventory(lastUpdatedAt);
    if (inventory.isEmpty) {
      print('✅ No new inventory items to sync');
      return;
    }
    
    String latestUpdatedAt = lastUpdatedAt;
    
    // Update acquiredAt for foods in inventory
    for (final item in inventory) {
      final foodId = item['food_id'];
      final acquiredAt = DateTime.parse(item['acquired_at']);
      
      await HiveHelper.instance.updateFoodAcquiredAt(foodId, acquiredAt);
      print('🎒 Updated food $foodId acquired at: $acquiredAt');
      
      // Track the latest updated_at
      if (item['updated_at'] != null) {
        final updatedAt = item['updated_at'];
        if (updatedAt.compareTo(latestUpdatedAt) > 0) {
          latestUpdatedAt = updatedAt;
        }
      }
    }
    
    await HiveHelper.instance.setLastUpdatedAt('inventory', latestUpdatedAt);
    
    print('✅ Synced ${inventory.length} inventory items');
    print('📅 Updated last sync time to: $latestUpdatedAt');
  } catch (e) {
    print('❌ Error syncing inventory: $e');
  }
}

Future<void> syncTodayMeal(SupabaseApi api) async {
  // TODO: Implement today's meal sync
}
