import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';

import '../models/food.dart';
import '../data/hive/hive_helper.dart';
import '../data/supabase/api_service.dart';
import '../utils/download_image.dart';
import '../utils/asset_image_manager.dart';

class PreloadData {
  final api = SupabaseApi();

  Future<void> preloadAllData() async {
    print('🔄 데이터 프리로드 시작...');

    try {
      final userId = await _syncUser();
      await _syncFoods();
      await _syncRecipes();
      if (userId != null) { 
        await _syncInventory(userId);
      }

      print('✅ 데이터 프리로드 완료!');
    } catch (e) {
      print('❌ 데이터 프리로드 실패: $e');
    }
  }

  /// assets에 이미지가 있는지 확인하는 함수
  static Future<bool> _isAssetAvailable(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> _syncUser() async {
    print('👤 유저 확인 시작...');
    final userInfo = HiveHelper.instance.getUserInfo();
    final userId = userInfo?['id']?.toString();
    print('📋 저장된 유저 ID: $userId');
    
    if (userId == null) {
      // DB에 유저 추가
      print('🆕 새 유저 생성 중...');
      final newUserInfo = await api.createUser();
      print('📊 생성된 유저 정보: $newUserInfo');
      
      // Hive에 사용자 정보 저장
      if (newUserInfo != null) {
        await HiveHelper.instance.saveUserInfo(newUserInfo);
        print('✅ 사용자 정보 Hive 저장 완료');
        
      } else {
        print('❌ 사용자 정보 생성 실패');
        
      }
    } else {
      print('✅ 기존 유저 확인됨: $userId');
      if (userId != null) {
        final lastUpdatedAt = HiveHelper.instance.getLastUpdatedAt('users') ?? '1970-01-01';
        final updatedUserInfo = await api.getUserInfo(userId, lastUpdatedAt);
        print('📊 업데이트된 유저 정보: $updatedUserInfo');
        
        // 업데이트된 정보가 있으면 Hive에 저장
        if (updatedUserInfo != null && updatedUserInfo.isNotEmpty) {
          await HiveHelper.instance.saveUserInfo(updatedUserInfo);
          print('✅ 사용자 정보 업데이트 완료');
        }
        
      } else {
        print('❌ 유저 ID가 null입니다');
      }
      return userId;
    }
  }

  Future<void> _syncFoods() async {
    print('🍽️ 음식 데이터 동기화 시작...');

    final lastUpdatedAt = HiveHelper.instance.getLastUpdatedAt('foods') ?? '1970-01-01';
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

    final lastUpdatedAt = HiveHelper.instance.getLastUpdatedAt('recipes') ?? '1970-01-01';
    print('📅 레시피 마지막 갱신일: $lastUpdatedAt');

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

      print('📝 음식 $resultId 레시피 업데이트: $requiredIds (updated_at: $updatedAt)');

      // 각 음식의 레시피 정보 업데이트
      await HiveHelper.instance.updateFoodRecipes(resultId, requiredIds);

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
  }

  Future<void> _syncInventory(String userId) async {
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
          'user_id': userId,
          'food_id': food.id,
          'acquired_at': food.acquiredAt!.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('📦 인벤토리 데이터 준비: 음식 ${food.id} (${food.name}) - ${food.acquiredAt}');
      }
    }

    // Supabase에 upsert
    try {
      final api = SupabaseApi();
      final result = await api.upsertInventory(inventoryData);
      print('✅ 인벤토리 데이터 upsert 완료: ${inventoryData.length}개');
      print('📊 Upsert 결과: $result');
    } catch (e) {
      print('❌ 인벤토리 데이터 upsert 실패: $e');
    }
  }
}

// 스크립트 실행용 main 함수
void main() async {
  final preloader = PreloadData();
  await preloader.preloadAllData();
}
