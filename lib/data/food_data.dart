import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/data/hive/hive_helper.dart';
import 'package:launchlunch/data/supabase/api_service.dart';
import 'package:collection/collection.dart';

class FoodDataManager {
  static final FoodDataManager _instance = FoodDataManager._internal();
  factory FoodDataManager() => _instance;
  FoodDataManager._internal();

  List<Food> _allFoods = [];
  List<Food> _availableFoods = [];

  List<Food> get allFoods => _allFoods;
  List<Food> get availableFoods => _availableFoods;

  /// Hive에서 음식 데이터를 로드합니다.
  Future<void> loadFoodsFromHive() async {
    try {
      // Hive에서 모든 음식 데이터 로드
      final hiveFoods = await HiveHelper.instance.getAllFoods();

      // Food 객체로 변환 (이미 Food 타입이므로 그대로 사용)
      final List<Food> foods = hiveFoods;

      _allFoods = foods;
      // 획득한 음식들만 사용 가능한 음식으로 설정 (acquired_at이 있는 것들)
      final acquiredFoods = foods.where((f) => f.acquiredAt != null).toList();

      // 획득일 순으로 정렬 (오래된 획득이 먼저, 최신 획득이 나중에)
      acquiredFoods.sort((a, b) {
        if (a.acquiredAt == null && b.acquiredAt == null) return 0;
        if (a.acquiredAt == null) return 1;
        if (b.acquiredAt == null) return -1;
        return a.acquiredAt!.compareTo(b.acquiredAt!);
      });

      _availableFoods = acquiredFoods;

      print('✅ Hive에서 ${foods.length}개의 음식 데이터 로드 완료');
      
      // food_id 20 특별 확인
      final food20 = foods.where((food) => food.id == 20).firstOrNull;
      if (food20 != null) {
        print('🎯 [블루베리주먹밥 추적] FoodDataManager에서 food_id 20 확인됨');
        print('📋 [블루베리주먹밥 추적] 이름: ${food20.name}, 레시피: ${food20.recipes}, 획득여부: ${food20.acquiredAt != null}');
        
        if (food20.recipes != null && food20.recipes!.isNotEmpty) {
          print('✅ [블루베리주먹밥 추적] food_id 20에 레시피 존재: ${food20.recipes}');
        } else {
          print('❌ [블루베리주먹밥 추적] food_id 20에 레시피가 없음!');
        }
      } else {
        print('❌ [블루베리주먹밥 추적] FoodDataManager에서 food_id 20을 찾을 수 없음!');
      }
      
      // 레시피 데이터 검증 로그 추가
      final foodsWithRecipes = foods.where((food) => food.recipes != null && food.recipes!.isNotEmpty).toList();
      print('🍽️ [데이터 로드] 레시피가 있는 음식: ${foodsWithRecipes.length}개');
      
      for (final food in foodsWithRecipes) {
        if (food.id != 20) {
          print('📋 [데이터 로드] 음식 ${food.id}(${food.name}): 레시피 ${food.recipes}');
        }
      }
      
      if (foodsWithRecipes.isEmpty) {
        print('⚠️ [데이터 로드] 경고: 레시피가 있는 음식이 하나도 없습니다!');
      }
    } catch (e) {
      print('❌ Hive 데이터 로드 실패: $e');
      rethrow;
    }
  }

  /// 레시피를 완성했을 때 호출
  Future<void> addCompletedRecipe(Food recipe) async {
    // Hive에 획득 상태 저장
    await HiveHelper.instance.updateFoodAcquiredAt(recipe.id, DateTime.now());

    // Supabase inventory에도 추가
    try {
      final userUUID = HiveHelper.instance.getUserUUID();
      if (userUUID != null) {
        final api = SupabaseApi();
        final now = DateTime.now().toIso8601String();
        final inventoryData = [
          {
            'user_uuid': userUUID,
            'food_id': recipe.id,
            'acquired_at': now,
          }
        ];

        final result = await api.insertInventory(inventoryData);
        if (result['partial_success'] == true) {
          print('✅ 조합 완성 음식 인벤토리 추가: ${recipe.name} (ID: ${recipe.id})');
          print('📊 인벤토리 추가 결과: 추가 ${result['success_count']}개');
          if (result['duplicate_count'] > 0) {
            print('ℹ️ 이미 존재했던 재료: ${result['duplicate_count']}개');
          }
        } else {
          print('❌ 조합 완성 음식 인벤토리 추가 실패: ${result['error']}');
        }
      }
    } catch (e) {
      print('❌ 조합 완성 음식 인벤토리 추가 실패: $e');
    }

    // availableFoods 업데이트 (획득한 음식들만, 획득일 순으로 정렬)
    final acquiredFoods = _allFoods.where((f) => f.acquiredAt != null).toList();

    // 획득일 순으로 정렬 (오래된 획득이 먼저, 최신 획득이 나중에)
    acquiredFoods.sort((a, b) {
      if (a.acquiredAt == null && b.acquiredAt == null) return 0;
      if (a.acquiredAt == null) return 1;
      if (b.acquiredAt == null) return -1;
      return a.acquiredAt!.compareTo(b.acquiredAt!);
    });

    _availableFoods = acquiredFoods;
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
    final ownedCount = _allFoods.where((f) => f.acquiredAt != null).length;
    return {
      'total': totalCount,
      'owned': ownedCount,
    };
  }
}
