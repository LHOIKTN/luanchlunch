import 'package:hive_flutter/hive_flutter.dart';
import '../../models/food.dart';
import '../../models/meal.dart';
import 'dart:convert';

class HiveHelper {
  static final HiveHelper instance = HiveHelper._internal();
  HiveHelper._internal();

  static const String _foodBoxName = 'foods';
  static const String _mealBoxName = 'meals';
  static const String _metadataBoxName = 'metadata';
  static const String _userBoxName = 'user';
  static Box<Food>? _foodBox;
  static Box<DailyMeal>? _mealBox;
  static Box<String>? _metadataBox;
  static Box<String>? _userBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(FoodAdapter());
    Hive.registerAdapter(DailyMealAdapter());
    _foodBox = await Hive.openBox<Food>(_foodBoxName);
    _mealBox = await Hive.openBox<DailyMeal>(_mealBoxName);
    _metadataBox = await Hive.openBox<String>(_metadataBoxName);
    _userBox = await Hive.openBox<String>(_userBoxName);
  }

  // Metadata management for last updated_at times
  String? getLastUpdatedAt(String tableName) {
    return _metadataBox?.get('last_updated_$tableName');
  }

  Future<void> resetMetadata(String boxName) async {
    await Hive.deleteBoxFromDisk(boxName);
  }

  Future<void> setLastUpdatedAt(String tableName, String updatedAt) async {
    await _metadataBox?.put('last_updated_$tableName', updatedAt);
  }

  String? getUserUUID() {
    return _metadataBox?.get('uuid');
  }

  // Save user info
  Future<void> saveUserInfo(Map<String, dynamic> userInfo) async {
    // UUID 저장 (문자열로 변환)
    if (userInfo['uuid'] != null) {
      await _metadataBox?.put('uuid', userInfo['uuid'].toString());
    }

    // 전체 사용자 정보를 JSON으로 저장
    final userInfoJson = jsonEncode(userInfo);
    await _metadataBox?.put('user_info', userInfoJson);

    print('✅ 사용자 정보 저장 완료: ${userInfo['uuid']}');
  }

  // Get user info
  Map<String, dynamic>? getUserInfo() {
    final userInfoJson = _metadataBox?.get('user_info');
    if (userInfoJson != null) {
      try {
        // JSON을 Map으로 변환
        final userInfo = jsonDecode(userInfoJson) as Map<String, dynamic>;
        return userInfo;
      } catch (e) {
        print('❌ 사용자 정보 파싱 실패: $e');
        return {};
      }
    }
    return {};
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
    final Map<int, Food> foodMap = {for (var food in foods) food.id: food};
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
    return _foodBox?.values.where((food) => food.acquiredAt != null).toList() ??
        [];
  }

  // Get foods that can be crafted (have recipes)
  List<Food> getCraftableFoods() {
    return _foodBox?.values
            .where((food) => food.recipes != null && food.recipes!.isNotEmpty)
            .toList() ??
        [];
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
    return craftableFoods
        .where((food) => canCraftFood(food.id, userInventory))
        .toList();
  }

  // DailyMeal 관련 메서드들

  // 모든 급식 데이터 가져오기
  List<DailyMeal> getAllMeals() {
    return _mealBox?.values.toList() ?? [];
  }

  // 특정 날짜의 급식 데이터 가져오기
  DailyMeal? getMealByDate(String mealDate) {
    return _mealBox?.get(mealDate);
  }

  // 급식 데이터 저장 또는 업데이트
  Future<void> saveMeal(DailyMeal meal) async {
    await _mealBox?.put(meal.mealDate, meal);
  }

  // 여러 급식 데이터 저장
  Future<void> saveMeals(List<DailyMeal> meals) async {
    final Map<String, DailyMeal> mealMap = {
      for (var meal in meals) meal.mealDate: meal
    };
    await _mealBox?.putAll(mealMap);
  }

  // 급식 데이터 upsert (있으면 업데이트, 없으면 추가)
  Future<void> upsertMeal(DailyMeal meal) async {
    final existingMeal = getMealByDate(meal.mealDate);
    if (existingMeal != null) {
      print('🔄 급식 데이터 업데이트: ${meal.mealDate}');
    } else {
      print('➕ 새로운 급식 데이터 추가: ${meal.mealDate}');
    }
    await _mealBox?.put(meal.mealDate, meal);
  }

  // 여러 급식 데이터 upsert
  Future<void> upsertMeals(List<DailyMeal> meals) async {
    print('🔄 ${meals.length}개의 급식 데이터 upsert 시작...');

    for (final meal in meals) {
      await upsertMeal(meal);
    }

    print('✅ 급식 데이터 upsert 완료');
  }

  // 가장 최근 급식 날짜 가져오기 (기본값: 1970-01-01)
  String getLatestMealDate() {
    final meals = getAllMeals();
    if (meals.isEmpty) {
      return '1970-01-01';
    }

    // mealDate를 기준으로 정렬하여 가장 최근 날짜 반환
    meals.sort((a, b) => b.mealDate.compareTo(a.mealDate));
    return meals.first.mealDate;
  }

  // 급식 데이터 삭제
  Future<void> deleteMeal(String mealDate) async {
    await _mealBox?.delete(mealDate);
  }

  // 모든 급식 데이터 삭제
  Future<void> clearAllMeals() async {
    await _mealBox?.clear();
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
    await _userBox?.close();
  }

  // 닉네임 관련 메서드들

  // 닉네임 저장
  Future<void> saveNickname(String nickname) async {
    await _userBox?.put('nickname', nickname);
    print('✅ 닉네임 저장 완료: $nickname');
  }

  // 닉네임 가져오기
  String getNickname() {
    return _userBox?.get('nickname', defaultValue: '') ?? '';
  }

  // 닉네임 삭제
  Future<void> deleteNickname() async {
    await _userBox?.delete('nickname');
    print('🗑️ 닉네임 삭제 완료');
  }

  // 기본 재료들 (쌀, 소금, 설탕, 참기름) 자동 획득
  Future<List<Map<String, dynamic>>> grantBasicIngredients() async {
    print('🎁 기본 재료 자동 획득 시작...');

    // 기본 재료들의 이름으로 ID 찾기
    final allFoods = getAllFoods();
    final basicIngredientNames = ['쌀', '소금', '설탕', '참기름'];
    final now = DateTime.now();
    final List<Map<String, dynamic>> grantedIngredients = [];

    for (final name in basicIngredientNames) {
      try {
        final food = allFoods.firstWhere((f) => f.name == name);

        if (food.acquiredAt == null) {
          // Hive에 획득 상태 업데이트
          await updateFoodAcquiredAt(food.id, now);
          print('✅ 기본 재료 획득: $name (ID: ${food.id})');

          // 반환할 리스트에 추가
          grantedIngredients.add({
            'id': food.id,
            'acquired_at': now.toIso8601String(),
          });
        } else {
          print('ℹ️ 이미 획득한 기본 재료: $name');
        }
      } catch (e) {
        print('⚠️ 기본 재료를 찾을 수 없음: $name');
      }
    }

    print('🎁 기본 재료 자동 획득 완료: ${grantedIngredients.length}개');
    return grantedIngredients;
  }
}
