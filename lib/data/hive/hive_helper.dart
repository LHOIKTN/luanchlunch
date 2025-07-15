import 'package:hive_flutter/hive_flutter.dart';
import '../../models/food.dart';

class HiveHelper {
  static final HiveHelper instance = HiveHelper._internal();
  HiveHelper._internal();

  static const String _foodBoxName = 'foods';
  static const String _metadataBoxName = 'metadata';
  static Box<Food>? _foodBox;
  static Box<String>? _metadataBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(FoodAdapter());
    _foodBox = await Hive.openBox<Food>(_foodBoxName);
    _metadataBox = await Hive.openBox<String>(_metadataBoxName);
  }

  // Metadata management for last updated_at times
  String getLastUpdatedAt(String tableName) {
    return _metadataBox?.get('last_updated_${tableName}') ?? '1970-01-01';
  }

  Future<void> setLastUpdatedAt(String tableName, String updatedAt) async {
    await _metadataBox?.put('last_updated_${tableName}', updatedAt);
  }

  // Get all foods
  List<Food> getAllFoods() {
    return _foodBox?.values.toList() ?? [];
  }

  // Get food by ID
  Food? getFoodById(int id) {
    return _foodBox?.get(id);
  }

  // Save or update food
  Future<void> saveFood(Food food) async {
    await _foodBox?.put(food.id, food);
  }

  // Save multiple foods
  Future<void> saveFoods(List<Food> foods) async {
    final Map<int, Food> foodMap = {
      for (var food in foods) food.id: food
    };
    await _foodBox?.putAll(foodMap);
  }

  // Update food recipes
  Future<void> updateFoodRecipes(int foodId, List<int> recipes) async {
    final food = _foodBox?.get(foodId);
    if (food != null) {
      final updatedFood = food.copyWith(recipes: recipes);
      await _foodBox?.put(foodId, updatedFood);
    }
  }

  // Update food acquiredAt
  Future<void> updateFoodAcquiredAt(int foodId, DateTime? acquiredAt) async {
    final food = _foodBox?.get(foodId);
    if (food != null) {
      final updatedFood = food.copyWith(acquiredAt: acquiredAt);
      await _foodBox?.put(foodId, updatedFood);
    }
  }

  // Get foods that user has acquired (acquiredAt is not null)
  List<Food> getAcquiredFoods() {
    return _foodBox?.values.where((food) => food.acquiredAt != null).toList() ?? [];
  }

  // Get foods that can be crafted (have recipes)
  List<Food> getCraftableFoods() {
    return _foodBox?.values.where((food) => food.recipes != null && food.recipes!.isNotEmpty).toList() ?? [];
  }

  // Check if user can craft a specific food
  bool canCraftFood(int foodId, List<int> userInventory) {
    final food = _foodBox?.get(foodId);
    if (food?.recipes == null) return false;
    
    for (final requiredId in food!.recipes!) {
      if (!userInventory.contains(requiredId)) {
        return false;
      }
    }
    return true;
  }

  // Get all craftable foods with current inventory
  List<Food> getAvailableCrafts(List<int> userInventory) {
    final craftableFoods = getCraftableFoods();
    return craftableFoods.where((food) => canCraftFood(food.id, userInventory)).toList();
  }

  // Clear all data
  Future<void> clearAll() async {
    await _foodBox?.clear();
    await _metadataBox?.clear();
  }

  // Clear specific table's last updated time
  Future<void> clearLastUpdatedAt(String tableName) async {
    await _metadataBox?.delete('last_updated_${tableName}');
    print('🗑️ $tableName 테이블의 마지막 갱신 시간 초기화됨');
  }

  // Reset all last updated times to default
  Future<void> resetAllLastUpdatedAt() async {
    await _metadataBox?.clear();
    print('🗑️ 모든 테이블의 마지막 갱신 시간 초기화됨');
  }

  // Close database
  Future<void> close() async {
    await _foodBox?.close();
    await _metadataBox?.close();
  }
} 