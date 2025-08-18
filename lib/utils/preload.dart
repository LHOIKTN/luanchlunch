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
      // 각각의 동기화를 개별적으로 try-catch 처리
      await _syncFoods();
      final userUUID = await _syncUser();
      await _syncRecipes();
      await _syncMeals();

      print('✅ 데이터 프리로드 완료!');
    } catch (e) {
      print('⚠️ 데이터 프리로드 중 오류 발생, 오프라인 모드로 계속 진행: $e');
    }
  }

  Future<String?> _syncUser() async {
    print('👤 유저 확인 시작...');
    final userUUID = HiveHelper.instance.getUserUUID();
    print('📋 저장된 유저 UUID: $userUUID');

    if (userUUID == null) {
      print('🆕 새 유저 생성 시작...');

      // 먼저 Hive에 기본 재료 추가 (오프라인에서도 플레이 가능하도록)
      print('🎁 오프라인 모드 대비 기본 재료 먼저 추가...');
      final grantedIngredients =
          await HiveHelper.instance.grantBasicIngredients();
      print('✅ Hive 기본 재료 추가 성공: ${grantedIngredients.length}개');

      // DB에 유저 추가
      print('🆕 Supabase에 새 유저 생성 중...');
      final newUserInfo = await api.createUser();
      print('📊 생성된 유저 정보: $newUserInfo');

      // Hive에 사용자 정보 저장
      if (newUserInfo != null) {
        await HiveHelper.instance.saveUserInfo(newUserInfo);
        print('✅ 사용자 정보 Hive 저장 완료');

        // 기존 동기화 함수로 Hive 획득 재료들을 Supabase에 동기화
        await syncAllAcquiredFoods(newUserInfo['uuid']);

        return newUserInfo['uuid'];
      } else {
        print('❌ 사용자 정보 생성 실패 (Hive 기본 재료는 이미 추가됨)');
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

      // 기존 사용자에게도 기본 재료가 없으면 제공
      await _grantBasicIngredientsToExistingUser(userUUID);

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

      // Supabase 연결 실패 시 빈 리스트 반환
      if (foodsData == null) {
        print('⚠️ Supabase 연결 실패, 기존 로컬 데이터 사용');
        return;
      }
      print('📊 Supabase 응답 데이터: ${foodsData.length}개');
      print('📋 첫 번째 데이터: ${foodsData.isNotEmpty ? foodsData.first : "없음"}');

      // food_id 20 확인
      final food20Data = foodsData.where((food) => food['id'] == 20).toList();
      if (food20Data.isNotEmpty) {
        print('🎯 [블루베리주먹밥 추적] foods 테이블에서 food_id 20 발견!');
        final food20 = food20Data.first;
        print(
            '📝 [블루베리주먹밥 추적] 음식 정보: id=${food20['id']}, name=${food20['name']}, image_url=${food20['image_url']}, updated_at=${food20['updated_at']}');
      } else {
        print('❌ [블루베리주먹밥 추적] foods 테이블에 food_id 20이 없습니다!');
        print(
            '🔍 [블루베리주먹밥 추적] 전체 food_id 목록: ${foodsData.map((f) => f['id']).toList()..sort()}');
      }

      if (foodsData.isEmpty) {
        print('✅ 새로운 음식 데이터가 없습니다.');
        return;
      }

      print('🔄 ${foodsData.length}개의 음식 데이터 처리 중...');

      // AssetImageManager 초기화 (assets 스캔)
      final assetImageManager = AssetImageManager();
      await assetImageManager.assetImages; // assets 스캔 실행

      final List<Food> updatedFoodList = [];
      String latestFoodUpdatedAt = lastUpdatedAt;

      for (final foodData in foodsData) {
        final int id = foodData['id'];
        final String name = foodData['name'];
        String imageUrl = foodData['image_url'];
        final String? detail = foodData['detail'];
        final String updatedAt = foodData['updated_at'];

        if (id == 20) {
          print(
              '🎯 [블루베리주먹밥 추적] 음식 데이터 처리 시작: ID=$id, 이름=$name, 이미지=$imageUrl');
          print('🔄 [블루베리주먹밥 추적] 최신 데이터로 모든 내용 교체 시작...');
        } else {
          print(
              '🍽️ 처리 중: ID=$id, 이름=$name, 이미지=$imageUrl (updated_at: $updatedAt)');
        }

        // 기존 음식 데이터 확인
        final existingFoods = HiveHelper.instance.getAllFoods();
        final existingFood = existingFoods.where((f) => f.id == id).firstOrNull;

        bool needsFullUpdate = true;
        if (existingFood != null) {
          if (id == 20) {
            print('📝 [블루베리주먹밥 추적] 기존 데이터 발견 - 최신 데이터로 전체 교체');
          }
          // 더 최신 데이터이므로 전체 교체 (이미지, 설명, 레시피 모두)
          needsFullUpdate = true;
        }

        String localImagePath = '';

        if (needsFullUpdate) {
          if (id == 20) {
            print('🔄 [블루베리주먹밥 추적] 이미지 교체 시작...');
          }

          // 이미지 경로 처리 (기존 이미지가 있어도 새로 다운로드)
          final assetPath = 'assets/images/$imageUrl';

          if (await assetImageManager.isAssetImage(assetPath)) {
            // assets에 있는 이미지는 그대로 사용
            localImagePath = assetPath;
            if (id == 20) {
              print('✅ [블루베리주먹밥 추적] Assets 이미지 사용: $name -> $localImagePath');
            } else {
              print('✅ Assets 이미지 사용: $name -> $localImagePath');
            }
          } else {
            // assets에 없는 이미지는 새로 다운로드 (기존 것 교체)
            try {
              if (id == 20) {
                print('⬇️ [블루베리주먹밥 추적] 최신 이미지 다운로드 중: $name');
              } else {
                print('⬇️ 최신 이미지 다운로드 중: $name');
              }
              final downloadedPath =
                  await downloadAndSaveImage(imageUrl, forceRedownload: true);
              if (downloadedPath != null) {
                localImagePath = downloadedPath;
                if (id == 20) {
                  print(
                      '✅ [블루베리주먹밥 추적] 최신 이미지 다운로드 완료: $name -> $localImagePath');
                } else {
                  print('✅ 최신 이미지 다운로드 완료: $name -> $localImagePath');
                }
              } else {
                if (id == 20) {
                  print('❌ [블루베리주먹밥 추적] 이미지 다운로드 실패: $name');
                } else {
                  print('❌ 이미지 다운로드 실패: $name');
                }
                localImagePath = imageUrl; // 원본 URL 사용
              }
            } catch (e) {
              if (id == 20) {
                print('❌ [블루베리주먹밥 추적] 이미지 다운로드 에러: $name -> $e');
              } else {
                print('❌ 이미지 다운로드 에러: $name -> $e');
              }
              localImagePath = imageUrl; // 원본 URL 사용
            }
          }
        }

        // Food 객체 생성 (모든 데이터 최신으로 교체)
        final updatedFood = Food(
          id: id,
          name: name,
          imageUrl: localImagePath,
          detail: detail, // 최신 설명으로 교체
          acquiredAt: existingFood?.acquiredAt, // 획득 상태는 유지
          recipes: existingFood?.recipes, // 레시피는 별도 동기화에서 처리
        );

        updatedFoodList.add(updatedFood);

        if (id == 20) {
          print('✅ [블루베리주먹밥 추적] Food 객체 생성 완료 - 최신 데이터로 교체됨');
        }

        // 음식 데이터의 최신 갱신일 추적
        if (updatedAt.compareTo(latestFoodUpdatedAt) > 0) {
          latestFoodUpdatedAt = updatedAt;
        }
      }

      // Hive에 업데이트된 음식들만 저장 (기존 데이터 유지하면서 업데이트)
      for (final updatedFood in updatedFoodList) {
        await HiveHelper.instance.upsertFood(updatedFood);

        if (updatedFood.id == 20) {
          print('✅ [블루베리주먹밥 추적] Hive 개별 업데이트 완료');
        }
      }

      // food_id 20이 저장되었는지 확인
      final savedFoods = HiveHelper.instance.getAllFoods();
      final savedFood20 = savedFoods.where((food) => food.id == 20).firstOrNull;
      if (savedFood20 != null) {
        print('✅ [블루베리주먹밥 추적] Hive 저장 후 food_id 20 확인됨: ${savedFood20.name}');
        print(
            '📝 [블루베리주먹밥 추적] 최신 정보: 이미지=${savedFood20.imageUrl}, 설명=${savedFood20.detail}');
      } else {
        print('❌ [블루베리주먹밥 추적] Hive 저장 후 food_id 20을 찾을 수 없음!');
      }

      // 저장된 데이터 확인
      print('📋 업데이트된 음식 데이터 확인:');
      for (final food in updatedFoodList) {
        if (food.id != 20) {
          print('  - ID: ${food.id}, 이름: ${food.name}, 이미지: ${food.imageUrl}');
        }
      }
      print('📋 총 ${updatedFoodList.length}개의 음식이 업데이트됨');

      // 음식 마지막 갱신일 업데이트 (foods 테이블용)
      if (latestFoodUpdatedAt != lastUpdatedAt) {
        await HiveHelper.instance
            .setLastUpdatedAt('foods', latestFoodUpdatedAt);
        print('📅 음식 마지막 갱신일 업데이트: $latestFoodUpdatedAt');
      }

      print('✅ 음식 데이터 동기화 완료: ${updatedFoodList.length}개 업데이트');
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
      // 🔧 수정: 부분 업데이트가 아닌 전체 레시피를 가져와서 완전 교체
      // updatedAt 조건을 사용하지 않고 전체 레시피를 가져옴
      final allRecipesData = await api.getRecipes('1970-01-01');

      if (allRecipesData.isEmpty) {
        print('❌ 전체 레시피 데이터가 비어있습니다!');
        return;
      }

      print('🔄 전체 ${allRecipesData.length}개의 레시피 데이터로 완전 교체 중...');
      print('📝 모든 레시피를 최신 데이터로 완전히 교체합니다.');

      // food_id 20 확인
      final food20Data =
          allRecipesData.where((recipe) => recipe['result_id'] == 20).toList();
      if (food20Data.isNotEmpty) {
        print('🎯 [블루베리주먹밥 추적] 전체 레시피에서 food_id 20 발견!');
      } else {
        print('❌ [블루베리주먹밥 추적] 전체 레시피에 food_id 20이 없습니다!');
      }

      String latestRecipeUpdatedAt = lastUpdatedAt;

      // 모든 레시피를 완전 교체
      for (final recipe in allRecipesData) {
        final int resultId = recipe['result_id'];
        final List<int> requiredIds = List<int>.from(recipe['required_ids']);
        final String updatedAt = recipe['updated_at'];

        if (resultId == 20) {
          print(
              '📝 [블루베리주먹밥 추적] 음식 $resultId 레시피 완전 교체: $requiredIds (updated_at: $updatedAt)');
        } else {
          print(
              '📝 [레시피 처리] 음식 $resultId 레시피 완전 교체: $requiredIds (updated_at: $updatedAt)');
        }

        // 각 음식의 레시피 정보를 최신 데이터로 완전 교체
        await HiveHelper.instance.updateFoodRecipes(resultId, requiredIds);

        if (resultId == 20) {
          print('✅ [블루베리주먹밥 추적] 음식 $resultId 레시피 완전 교체 완료');
        } else {
          print('✅ [레시피 처리] 음식 $resultId 레시피 완전 교체 완료');
        }

        // 레시피 데이터의 최신 갱신일 추적
        if (updatedAt.compareTo(latestRecipeUpdatedAt) > 0) {
          latestRecipeUpdatedAt = updatedAt;
        }
      }

      // 레시피 마지막 갱신일 업데이트 (recipes 테이블용) - 최신 시점으로 갱신
      if (latestRecipeUpdatedAt != lastUpdatedAt) {
        await HiveHelper.instance
            .setLastUpdatedAt('recipes', latestRecipeUpdatedAt);
        print('📅 레시피 마지막 갱신일 최신으로 업데이트: $latestRecipeUpdatedAt');
      }

      print('✅ 레시피 데이터 완전 교체 완료: ${allRecipesData.length}개 조합 모두 최신 데이터로 교체');

      // 동기화 후 Hive에서 레시피가 포함된 음식들 확인
      await _verifyRecipesInHive();
    } catch (e) {
      print('❌ 레시피 데이터 동기화 실패: $e');
      print('❌ 에러 상세: ${e.toString()}');
    }
  }

  /// 누락된 레시피 처리 (강제 재동기화)
  Future<void> _handleMissingRecipes() async {
    print('🔄 [강제 재동기화] 누락된 레시피 처리 시작...');

    try {
      // 전체 레시피 다시 가져오기 (updatedAt 조건 없이)
      print('📋 [강제 재동기화] 전체 레시피 재조회 시작...');
      final allRecipesData = await api.getRecipes('1970-01-01');

      if (allRecipesData.isEmpty) {
        print('❌ [강제 재동기화] 전체 레시피도 비어있음');
        return;
      }

      print('📊 [강제 재동기화] 전체 레시피 ${allRecipesData.length}개 발견');

      // 모든 레시피를 완전 교체 (food_id 20만이 아닌 전체)
      for (final recipe in allRecipesData) {
        final int resultId = recipe['result_id'];
        final List<int> requiredIds = List<int>.from(recipe['required_ids']);

        if (resultId == 20) {
          print('🔧 [강제 재동기화] food_id $resultId 레시피 강제 업데이트: $requiredIds');
        } else {
          print('🔧 [강제 재동기화] food_id $resultId 레시피 강제 업데이트: $requiredIds');
        }

        await HiveHelper.instance.updateFoodRecipes(resultId, requiredIds);

        if (resultId == 20) {
          print('✅ [강제 재동기화] food_id $resultId 레시피 업데이트 완료');
        } else {
          print('✅ [강제 재동기화] food_id $resultId 레시피 업데이트 완료');
        }
      }

      // 레시피 마지막 갱신일을 현재 시간으로 리셋 (다음에는 정상 동기화되도록)
      await HiveHelper.instance
          .setLastUpdatedAt('recipes', DateTime.now().toIso8601String());
      print('📅 [강제 재동기화] 레시피 마지막 갱신일 리셋 완료');

      print('✅ [강제 재동기화] 전체 레시피 ${allRecipesData.length}개 완전 교체 완료');
    } catch (e) {
      print('❌ [강제 재동기화] 실패: $e');
    }
  }

  /// Hive에 저장된 레시피 데이터 검증
  Future<void> _verifyRecipesInHive() async {
    print('🔍 [레시피 검증] Hive에 저장된 레시피 데이터 확인 시작...');

    final allFoods = HiveHelper.instance.getAllFoods();
    final foodsWithRecipes = allFoods
        .where((food) => food.recipes != null && food.recipes!.isNotEmpty)
        .toList();

    print(
        '📊 [레시피 검증] 전체 음식: ${allFoods.length}개, 레시피 있는 음식: ${foodsWithRecipes.length}개');

    // food_id 20 특별 확인
    final food20 = allFoods.where((food) => food.id == 20).firstOrNull;
    if (food20 != null) {
      if (food20.recipes != null && food20.recipes!.isNotEmpty) {
        print('✅ [블루베리주먹밥 추적] Hive에서 food_id 20 레시피 확인: ${food20.recipes}');
      } else {
        print('❌ [블루베리주먹밥 추적] Hive에서 food_id 20의 레시피가 null 또는 비어있음!');
        print(
            '🔍 [블루베리주먹밥 추적] food_id 20 정보: 이름=${food20.name}, 레시피=${food20.recipes}');
      }
    } else {
      print('❌ [블루베리주먹밥 추적] Hive에서 food_id 20 음식 자체를 찾을 수 없음!');
    }

    for (final food in foodsWithRecipes) {
      if (food.id != 20) {
        print('🍽️ [레시피 검증] 음식 ${food.id}(${food.name}): 레시피 ${food.recipes}');
      }
    }

    if (foodsWithRecipes.isEmpty) {
      print('⚠️ [레시피 검증] 경고: Hive에 레시피가 포함된 음식이 하나도 없습니다!');
    }
  }

  /// 개발자용: 레시피 강제 전체 재동기화
  Future<void> forceRecipesResync() async {
    print('🔄 [개발자 도구] 레시피 강제 전체 재동기화 시작...');

    try {
      // 레시피 마지막 갱신일을 1970년으로 리셋
      await HiveHelper.instance.setLastUpdatedAt('recipes', '1970-01-01');
      print('📅 [개발자 도구] 레시피 마지막 갱신일 리셋: 1970-01-01');

      // 전체 레시피 재동기화
      await _syncRecipes();

      print('✅ [개발자 도구] 레시피 강제 전체 재동기화 완료');
    } catch (e) {
      print('❌ [개발자 도구] 레시피 강제 재동기화 실패: $e');
    }
  }

  /// 개발자용: 특정 음식의 레시피 직접 업데이트
  Future<void> forceUpdateSpecificRecipe(int foodId) async {
    print('🔄 [개발자 도구] food_id $foodId 레시피 직접 업데이트 시작...');

    try {
      // 해당 음식의 레시피 직접 조회
      final response = await api.getSpecificFoodRecipe(foodId);

      if (response.isNotEmpty) {
        final recipe = response.first;
        final List<int> requiredIds = List<int>.from(recipe['required_ids']);

        print('📝 [개발자 도구] food_id $foodId 레시피 직접 업데이트: $requiredIds');
        await HiveHelper.instance.updateFoodRecipes(foodId, requiredIds);
        print('✅ [개발자 도구] food_id $foodId 레시피 업데이트 완료');
      } else {
        print('❌ [개발자 도구] food_id $foodId 레시피를 찾을 수 없음');
      }
    } catch (e) {
      print('❌ [개발자 도구] food_id $foodId 레시피 업데이트 실패: $e');
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
          print(
              '✅ Supabase 기본 재료 추가 성공: 추가 ${result['data']?['success_count'] ?? 0}개');
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

  Future<void> _grantBasicIngredientsToExistingUser(String userUUID) async {
    print('🎁 기존 사용자 기본 재료 확인 및 제공 시작...');

    try {
      // 현재 획득한 재료들 확인
      final acquiredFoods = HiveHelper.instance.getAcquiredFoods();
      final basicIngredientNames = ['쌀', '밀', '깨', '소금', '설탕', '육수'];

      // 기본 재료 중 획득하지 않은 것들 찾기
      final missingBasicIngredients = <String>[];
      for (final name in basicIngredientNames) {
        final hasIngredient = acquiredFoods.any((food) => food.name == name);
        if (!hasIngredient) {
          missingBasicIngredients.add(name);
        }
      }

      if (missingBasicIngredients.isEmpty) {
        print('ℹ️ 기존 사용자가 이미 모든 기본 재료를 보유하고 있습니다.');
        return;
      }

      print('📋 누락된 기본 재료: ${missingBasicIngredients.join(', ')}');

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

        if (result['success'] == true) {
          print('✅ Supabase 기본 재료 추가 성공: ${result['processed_count']}개');
        } else {
          print('⚠️ Supabase 기본 재료 추가 실패: ${result['error']}');
        }
      }

      print('🎁 기존 사용자 기본 재료 제공 완료');
    } catch (e) {
      print('❌ 기존 사용자 기본 재료 제공 실패: $e');
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
void main(List<String> args) async {
  final preloader = PreloadData();

  if (args.isNotEmpty) {
    final command = args[0];
    switch (command) {
      case 'force-recipes':
        print('🔄 레시피 강제 재동기화 실행...');
        await preloader.forceRecipesResync();
        break;
      case 'force-food20':
        print('🔄 food_id 20 강제 업데이트 실행...');
        await preloader.forceUpdateSpecificRecipe(20);
        break;
      case 'full-sync':
        print('🔄 전체 데이터 재동기화 실행...');
        await preloader.preloadAllData();
        break;
      default:
        print('❓ 알 수 없는 명령어: $command');
        print('📖 사용 가능한 명령어:');
        print('  - force-recipes: 레시피 강제 재동기화');
        print('  - force-food20: food_id 20 강제 업데이트');
        print('  - full-sync: 전체 데이터 재동기화');
        break;
    }
  } else {
    print('🚀 전체 데이터 동기화 실행...');
    await preloader.preloadAllData();
  }
}
