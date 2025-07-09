import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/inventory.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  // 예시: 재료 목록 불러오기
  Future<List<Ingredient>> fetchIngredients() async {
    final response = await supabase.from('ingredients').select();
    return (response as List)
        .map((json) => Ingredient.fromJson(json))
        .toList();
  }

  // 예시: 인벤토리 불러오기
  Future<List<InventoryItem>> fetchInventory(String userId) async {
    final response = await supabase
        .from('user_ingredients')
        .select()
        .eq('user_id', userId);
    return (response as List)
        .map((json) => InventoryItem.fromJson(json))
        .toList();
  }

  // 예시: 재료 획득(추가)
  Future<void> addInventoryItem(String userId, String ingredientId) async {
    await supabase.from('user_ingredients').insert({
      'user_id': userId,
      'ingredient_id': ingredientId,
      'acquired_at': DateTime.now().toIso8601String(),
    });
  }

  // 예시: 레시피 목록 불러오기
  Future<List<Recipe>> fetchRecipes() async {
    final response = await supabase.from('recipes').select();
    return (response as List)
        .map((json) => Recipe.fromJson(json))
        .toList();
  }
} 