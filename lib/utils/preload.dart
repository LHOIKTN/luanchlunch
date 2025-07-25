import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';

import '../models/food.dart';
import '../data/hive/hive_helper.dart';
import '../data/supabase/api_service.dart';
import '../utils/download_image.dart';
import '../utils/asset_image_manager.dart';
import '../models/meal.dart';

class PreloadData {
  final api = SupabaseApi();

  Future<void> preloadAllData() async {
    print('🔄 데이터 프리로드 시작...');

    try {
      await _syncFoods();
      final userUUID = await _syncUser();
      await _syncRecipes();
      await _syncMeals();
      // _syncInventory는 _syncUser 내부에서 이미 호출됨 (기존 사용자의 경우)

      print('✅ 데이터 프리로드 완료!');
    } catch (e) {
      print('❌ 데이터 프리로드 실패: $e');
    }
  }

  Future<String?> _syncUser() async {
    print('👤 유저 확인 시작...');
    final userUUID = HiveHelper.instance.getUserUUID();
    print('📋 저장된 유저 UUID: $userUUID');

    if (userUUID == null) {
      // DB에 유저 추가
      print('🆕 새 유저 생성 중...');
      final newUserInfo = await api.createUser();
      print('📊 생성된 유저 정보: $newUserInfo');

      // Hive에 사용자 정보 저장
      if (newUserInfo != null) {
        await HiveHelper.instance.saveUserInfo(newUserInfo);
        print('✅ 사용자 정보 Hive 저장 완료');

        // 새 사용자에게 기본 재료 자동 획득
        await _grantBasicIngredientsToNewUser(newUserInfo['uuid']);
      } else {
        print('❌ 사용자 정보 생성 실패');
      }
    } else {
      print('✅ 기존 유저 확인됨: $userUUID');
      final lastUpdatedAt =
          HiveHelper.instance.getLastUpdatedAt('users') ?? '1970-01-01';
      final updatedUserInfo = await api.getUserInfo(userUUID, lastUpdatedAt);
      print('📊 업데이트된 유저 정보: $updatedUserInfo');

      // 업데이트된 정보가 있으면 Hive에 저장
      if (updatedUserInfo != null && updatedUserInfo.isNotEmpty) {
        await HiveHelper.instance.saveUserInfo(updatedUserInfo);
        print('✅ 사용자 정보 업데이트 완료');
      }

      // 기존 사용자의 모든 획득된 재료 데이터를 Supabase에 동기화
      await syncAllAcquiredFoods(userUUID);

      return userUUID;
    }
  }

  Future<void> _syncFoods() async {
    print('🍽️ 음식 데이터 동기화 시작...');

    final lastUpdatedAt =
        HiveHelper.instance.getLastUpdatedAt('foods') ?? '1970-01-01';
    print('📅 음식 마지막 갱신일: $lastUpdatedAt');

    try {
      print('🔗 Supabase API 인스턴스 생성 완료');

      final foodsData = await api.getFoodDatas(lastUpdatedAt);
      print('📊 Supabase 응답 데이터: ${foodsData.length}개');
      print('📋 첫 번째 데이터: ${foodsData.isNotEmpty ? foodsData.first : "없음"}');

      if (foodsData.isEmpty) {
        print('✅ 새로운 음식 데이터가 없습니다.');
        return;
      }

      print('🔄 ${foodsData.length}개의 음식 데이터 처리 중...');

      // AssetImageManager 초기화 (assets 스캔)
      final assetImageManager = AssetImageManager();
      await assetImageManager.assetImages; // assets 스캔 실행

      final List<Food> foodList = [];
      String latestFoodUpdatedAt = lastUpdatedAt;

      for (final foodData in foodsData) {
        final int id = foodData['id'];
        final String name = foodData['name'];
        String imageUrl = foodData['image_url'];
        final String? detail = foodData['detail'];
        final String updatedAt = foodData['updated_at'];

        print('🍽️ 처리 중: ID=$id, 이름=$name, 이미지=$imageUrl');

        // 이미지 경로 처리
        String localImagePath = '';

        // AssetImageManager를 사용하여 이미지 타입 확인
        final assetPath = 'assets/images/$imageUrl';

        if (await assetImageManager.isAssetImage(assetPath)) {
          // assets에 있는 이미지는 그대로 사용
          localImagePath = assetPath;
          print('✅ Assets 이미지 사용: $name -> $localImagePath');
        } else {
          // assets에 없는 이미지만 다운로드
          try {
            print('⬇️ Supabase에서 다운로드 중: $name');
            final downloadedPath = await downloadAndSaveImage(imageUrl);
            if (downloadedPath != null) {
              localImagePath = downloadedPath;
              print('✅ 다운로드 완료: $name -> $localImagePath');
            } else {
              print('❌ 다운로드 실패: $name');
              localImagePath = ''; // 원본 URL 유지
            }
          } catch (e) {
            print('❌ 다운로드 에러: $name -> $e');
            localImagePath = ''; // 원본 URL 유지
          }
        }

        // Food 객체 생성
        final food = Food(
          id: id,
          name: name,
          imageUrl: localImagePath,
          detail: detail,
        );

        if (localImagePath != '') {
          foodList.add(food);
        }

        // 음식 데이터의 최신 갱신일 추적
        if (updatedAt.compareTo(latestFoodUpdatedAt) > 0) {
          latestFoodUpdatedAt = updatedAt;
        }
      }

      // Hive에 저장
      await HiveHelper.instance.saveFoods(foodList);

      // 저장된 데이터 확인
      print('📋 Hive에 저장된 음식 데이터 확인:');
      final savedFoods = HiveHelper.instance.getAllFoods();
      for (final food in savedFoods) {
        print('  - ID: ${food.id}, 이름: ${food.name}, 이미지: ${food.imageUrl}');
      }
      print('📋 총 ${savedFoods.length}개의 음식이 Hive에 저장됨');

      // 음식 마지막 갱신일 업데이트 (foods 테이블용)
      if (latestFoodUpdatedAt != lastUpdatedAt) {
        await HiveHelper.instance
            .setLastUpdatedAt('foods', latestFoodUpdatedAt);
        print('📅 음식 마지막 갱신일 업데이트: $latestFoodUpdatedAt');
      }

      print('✅ 음식 데이터 동기화 완료: ${foodList.length}개');
    } catch (e) {
      print('❌ 음식 데이터 동기화 실패: $e');
      print('❌ 에러 상세: ${e.toString()}');
    }
  }

  Future<void> _syncRecipes() async {
    print('📋 레시피 데이터 동기화 시작...');

    final lastUpdatedAt =
        HiveHelper.instance.getLastUpdatedAt('recipes') ?? '1970-01-01';
    print('📅 레시피 마지막 갱신일: $lastUpdatedAt');

    try {
      final recipesData = await api.getRecipes(lastUpdatedAt);

      if (recipesData.isEmpty) {
        print('✅ 새로운 레시피 데이터가 없습니다.');
        return;
      }

      print('🔄 ${recipesData.length}개의 레시피 데이터 처리 중...');

      String latestRecipeUpdatedAt = lastUpdatedAt;

      // 이미 result_id로 그룹핑된 데이터 처리
      for (final recipe in recipesData) {
        final int resultId = recipe['result_id'];
        final List<int> requiredIds = List<int>.from(recipe['required_ids']);
        final String updatedAt = recipe['updated_at'];

        print('📝 [레시피 처리] 음식 $resultId 레시피 업데이트: $requiredIds (updated_at: $updatedAt)');

        // 각 음식의 레시피 정보 업데이트
        await HiveHelper.instance.updateFoodRecipes(resultId, requiredIds);
        print('✅ [레시피 처리] 음식 $resultId 레시피 Hive 업데이트 완료');

        // 레시피 데이터의 최신 갱신일 추적
        if (updatedAt.compareTo(latestRecipeUpdatedAt) > 0) {
          latestRecipeUpdatedAt = updatedAt;
        }
      }

      // 레시피 마지막 갱신일 업데이트 (recipes 테이블용)
      if (latestRecipeUpdatedAt != lastUpdatedAt) {
        await HiveHelper.instance
            .setLastUpdatedAt('recipes', latestRecipeUpdatedAt);
        print('📅 레시피 마지막 갱신일 업데이트: $latestRecipeUpdatedAt');
      }

      print('✅ 레시피 데이터 동기화 완료: ${recipesData.length}개 조합');
      
      // 동기화 후 Hive에서 레시피가 포함된 음식들 확인
      await _verifyRecipesInHive();
    } catch (e) {
      print('❌ 레시피 데이터 동기화 실패: $e');
      print('❌ 에러 상세: ${e.toString()}');
    }
  }

  /// Hive에 저장된 레시피 데이터 검증
  Future<void> _verifyRecipesInHive() async {
    print('🔍 [레시피 검증] Hive에 저장된 레시피 데이터 확인 시작...');
    
    final allFoods = HiveHelper.instance.getAllFoods();
    final foodsWithRecipes = allFoods.where((food) => food.recipes != null && food.recipes!.isNotEmpty).toList();
    
    print('📊 [레시피 검증] 전체 음식: ${allFoods.length}개, 레시피 있는 음식: ${foodsWithRecipes.length}개');
    
    for (final food in foodsWithRecipes) {
      print('🍽️ [레시피 검증] 음식 ${food.id}(${food.name}): 레시피 ${food.recipes}');
    }
    
    if (foodsWithRecipes.isEmpty) {
      print('⚠️ [레시피 검증] 경고: Hive에 레시피가 포함된 음식이 하나도 없습니다!');
    }
  }

  Future<void> _syncMeals() async {
    print('🍽️ 급식 데이터 동기화 시작...');

    final lastMealDate = HiveHelper.instance.getLatestMealDate();
    print('📅 급식 마지막 갱신일: $lastMealDate');

    try {
      final mealsData = await api.getMeals(lastMealDate);
      print('📊 Supabase 응답 데이터: ${mealsData.length}개');

      if (mealsData.isEmpty) {
        print('✅ 새로운 급식 데이터가 없습니다.');
        return;
      }

      print('🔄 ${mealsData.length}개의 급식 데이터 처리 중...');

      final List<DailyMeal> mealList = [];

      for (final mealData in mealsData) {
        final String lunchDate = mealData['lunch_date'];
        final String menuList = mealData['menu_list'] ?? '';
        final List<int> foods = List<int>.from(mealData['foods'] ?? []);

        print('🍽️ 처리 중: 날짜=$lunchDate, 메뉴=$menuList, 음식=${foods.length}개');

        // DailyMeal 객체 생성
        final meal = DailyMeal(
          lunchDate: lunchDate,
          menuList: menuList,
          foods: foods,
          isAcquired: false, // 기본적으로 미획득 상태
        );
        print(meal);
        mealList.add(meal);
      }

      // Hive에 upsert (있으면 업데이트, 없으면 추가)
      await HiveHelper.instance.upsertMeals(mealList);

      // 저장된 데이터 확인
      print('📋 Hive에 저장된 급식 데이터 확인:');
      final savedMeals = HiveHelper.instance.getAllMeals();
      for (final meal in savedMeals) {
        print(
            '  - 날짜: ${meal.lunchDate}, 메뉴: ${meal.menuList}, 음식: ${meal.foods.length}개');
      }
      print('📋 총 ${savedMeals.length}개의 급식이 Hive에 저장됨');

      print('✅ 급식 데이터 동기화 완료: ${mealList.length}개');
    } catch (e) {
      print('❌ 급식 데이터 동기화 실패: $e');
      print('❌ 에러 상세: ${e.toString()}');
    }
  }

  Future<void> _grantBasicIngredientsToNewUser(String userUUID) async {
    print('🎁 새 사용자 기본 재료 자동 획득 시작...');

    try {
      // Hive에 기본 재료들 획득 상태 추가
      final grantedIngredients =
          await HiveHelper.instance.grantBasicIngredients();
      print('✅ Hive 기본 재료 추가 성공: ${grantedIngredients.length}개');

      // Supabase에 기본 재료들 추가
      if (grantedIngredients.isNotEmpty) {
        final basicIngredientIds = grantedIngredients
            .map((ingredient) => ingredient['id'] as int)
            .toList();

        print('🔄 Supabase에 기본 재료 추가 중: $basicIngredientIds');
        final result = await api.addBasicIngredientsToInventory(
            userUUID, basicIngredientIds);

        if (result['partial_success'] == true) {
          print('✅ Supabase 기본 재료 추가 성공: 추가 ${result['data']?['success_count'] ?? 0}개');
          if (result['data']?['duplicate_count'] > 0) {
            print('ℹ️ 이미 존재하는 재료: ${result['data']?['duplicate_count']}개');
          }
          if (result['data']?['fail_count'] > 0) {
            print('⚠️ 실패: ${result['data']?['fail_count']}개');
          }
        } else {
          print('⚠️ Supabase 기본 재료 추가 실패: ${result['error']}');
          // Hive에서 롤백 (선택사항)
          print('⚠️ Hive 데이터는 유지하고 Supabase 동기화만 실패');
        }
      } else {
        print('ℹ️ 기본 재료가 이미 모두 획득되어 있습니다.');
      }

      print('🎁 새 사용자 기본 재료 자동 획득 완료');
    } catch (e) {
      print('❌ 기본 재료 자동 획득 실패: $e');
      print('❌ 에러 상세: ${e.toString()}');
    }
  }

  Future<void> syncAllAcquiredFoods(String userUUID) async {
    print('🎒 기존 사용자 모든 획득 재료 동기화 시작... (Hive → Supabase)');

    // Hive에서 획득한 음식들 조회
    final acquiredFoods = HiveHelper.instance.getAcquiredFoods();
    print('📋 Hive에서 획득한 음식 ${acquiredFoods.length}개 발견');

    if (acquiredFoods.isEmpty) {
      print('✅ 동기화할 획득 재료 데이터가 없습니다.');
      return;
    }

    // Supabase에 upsert할 데이터 준비
    final List<Map<String, dynamic>> inventoryData = [];

    for (final food in acquiredFoods) {
      if (food.acquiredAt != null) {
        inventoryData.add({
          'user_uuid': userUUID,
          'food_id': food.id,
          'acquired_at': food.acquiredAt!.toIso8601String(),
        });
        print(
            '📦 획득 재료 데이터 준비: 음식 ${food.id} (${food.name}) - ${food.acquiredAt}');
      }
    }

    // Supabase에 upsert
    try {
      final result = await api.insertInventory(inventoryData);
      if (result['partial_success'] == true) {
        print('✅ 획득 재료 데이터 동기화 완료: 추가 ${result['success_count']}개');
        if (result['duplicate_count'] > 0) {
          print('ℹ️ 이미 존재하는 재료: ${result['duplicate_count']}개');
        }
        if (result['fail_count'] > 0) {
          print('⚠️ 실패: ${result['fail_count']}개');
          print('📋 실패 상세: ${result['errors']?.join(', ')}');
        }
      } else {
        print('❌ 획득 재료 데이터 동기화 전체 실패: ${result['error']}');
      }
    } catch (e) {
      print('❌ 획득 재료 데이터 동기화 실패: $e');
    }
  }

  Future<void> _syncInventory(String userUUID) async {
    print('🎒 인벤토리 데이터 동기화 시작... (Hive → Supabase)');

    // Hive에서 획득한 음식들 조회
    final acquiredFoods = HiveHelper.instance.getAcquiredFoods();
    print('📋 Hive에서 획득한 음식 ${acquiredFoods.length}개 발견');

    if (acquiredFoods.isEmpty) {
      print('✅ 동기화할 인벤토리 데이터가 없습니다.');
      return;
    }

    // Supabase에 upsert할 데이터 준비
    final List<Map<String, dynamic>> inventoryData = [];

    for (final food in acquiredFoods) {
      if (food.acquiredAt != null) {
        inventoryData.add({
          'user_uuid': userUUID,
          'food_id': food.id,
          'acquired_at': food.acquiredAt!.toIso8601String(),
        });
        print(
            '📦 인벤토리 데이터 준비: 음식 ${food.id} (${food.name}) - ${food.acquiredAt}');
      }
    }

    // Supabase에 upsert (기존 api 인스턴스 사용)
    try {
      final result = await api.insertInventory(inventoryData);
      if (result['partial_success'] == true) {
        print('✅ 인벤토리 데이터 동기화 완료: 추가 ${result['success_count']}개');
        if (result['duplicate_count'] > 0) {
          print('ℹ️ 이미 존재하는 재료: ${result['duplicate_count']}개');
        }
        if (result['fail_count'] > 0) {
          print('⚠️ 실패: ${result['fail_count']}개');
          print('📋 실패 상세: ${result['errors']?.join(', ')}');
        }
      } else {
        print('❌ 인벤토리 데이터 동기화 전체 실패: ${result['error']}');
      }
    } catch (e) {
      print('❌ 인벤토리 데이터 동기화 실패: $e');
    }
  }
}

// 스크립트 실행용 main 함수
void main() async {
  final preloader = PreloadData();
  await preloader.preloadAllData();
}
