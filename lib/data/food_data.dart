import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/data/hive/hive_helper.dart';
import 'package:collection/collection.dart';

class FoodDataManager {
  static final FoodDataManager _instance = FoodDataManager._internal();
  factory FoodDataManager() => _instance;
  FoodDataManager._internal();

  List<Food> _allFoods = [];
  List<Food> _availableFoods = [];
  Set<int> _ownedRecipeIds = {};

  List<Food> get allFoods => _allFoods;
  List<Food> get availableFoods => _availableFoods;
  Set<int> get ownedRecipeIds => _ownedRecipeIds;

  /// Hive에서 음식 데이터를 로드합니다.
  Future<void> loadFoodsFromHive() async {
    try {
      // Hive에서 모든 음식 데이터 로드
      final hiveFoods = await HiveHelper.instance.getAllFoods();
      
      // Food 객체로 변환 (이미 Food 타입이므로 그대로 사용)
      final List<Food> foods = hiveFoods;

      _allFoods = foods;
      // 레시피가 없는 원재료들만 사용 가능한 음식으로 설정
      _availableFoods = foods.where((f) => f.recipes == null).toList();

      print('✅ Hive에서 ${foods.length}개의 음식 데이터 로드 완료');
    } catch (e) {
      print('❌ Hive 데이터 로드 실패: $e');
      rethrow;
    }
  }

  /// 레시피를 완성했을 때 호출
  void addCompletedRecipe(Food recipe) {
    _ownedRecipeIds.add(recipe.id);
    if (!_availableFoods.any((f) => f.id == recipe.id)) {
      _availableFoods.add(recipe);
    }
  }

  /// 선택된 재료들로 레시피를 찾습니다.
  Food? findRecipeForIngredients(List<Food> selectedFoods) {
    if (selectedFoods.length < 2) return null;
    
    // 선택된 재료들의 ID로 레시피 매칭
    final selectedIds = selectedFoods.map((f) => f.id).toList()..sort();
    
    // 모든 음식 중에서 레시피가 있는 것들을 확인
    for (final food in _allFoods) {
      if (food.recipes != null) {
        final recipeIds = List<int>.from(food.recipes!)..sort();
        if (recipeIds.length == selectedIds.length &&
            const ListEquality().equals(recipeIds, selectedIds)) {
          return food;
        }
      }
    }
    
    return null;
  }

  /// 전체 음식 수와 획득한 음식 수를 반환합니다.
  Map<String, int> getProgressStats() {
    final totalCount = _allFoods.length;
    final ownedCount = _ownedRecipeIds.length;
    return {
      'total': totalCount,
      'owned': ownedCount,
    };
  }
} 