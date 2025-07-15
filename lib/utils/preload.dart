import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';

import '../models/food.dart';
import '../data/hive/hive_helper.dart';
import '../data/supabase/api_service.dart';
import '../utils/download_image.dart';

class PreloadData {
  static Future<void> preloadAllData() async {
    print('🔄 데이터 프리로드 시작...');
    
    try {
      await _syncFoods();
      await _syncRecipes();
      // await _syncInventory();
      
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

  static Future<void> _syncFoods() async {
    print('🍽️ 음식 데이터 동기화 시작...');
    
    final lastUpdatedAt = HiveHelper.instance.getLastUpdatedAt('foods');
    print('📅 마지막 갱신일: $lastUpdatedAt');
    
    try {
      final api = SupabaseApi();
      print('🔗 Supabase API 인스턴스 생성 완료');
      
      final foodsData = await api.getFoodDatas(lastUpdatedAt);
      print('📊 Supabase 응답 데이터: ${foodsData.length}개');
      print('📋 첫 번째 데이터: ${foodsData.isNotEmpty ? foodsData.first : "없음"}');
      
      if (foodsData.isEmpty) {
        print('✅ 새로운 음식 데이터가 없습니다.');
        return;
      }
      
      print('🔄 ${foodsData.length}개의 음식 데이터 처리 중...');
      
      final List<Food> foodList = [];
      String latestUpdatedAt = lastUpdatedAt;
      
      for (final foodData in foodsData) {
        final int id = foodData['id'];
        final String name = foodData['name'];
        String imageUrl = foodData['image_url'];
        final String updatedAt = foodData['updated_at'];
        
        print('🍽️ 처리 중: ID=$id, 이름=$name, 이미지=$imageUrl');
        
        // 이미지 경로 처리
        String localImagePath = '';
        
        // 1. assets에 이미 있는지 확인
        final assetPath = 'assets/images/${name.toLowerCase().replaceAll(' ', '_')}.webp';
        final assetFile = File(assetPath);
        
        if (await assetFile.exists()) {
          localImagePath = assetPath;
          print('✅ Assets에서 발견: $name -> $localImagePath');
        } else {
          // 2. Supabase bucket에서 다운로드
          try {
            print('⬇️ 다운로드 중: $name');
            final downloadedPath = await downloadAndSaveImage(imageUrl);
            if (downloadedPath != null) {
              localImagePath = downloadedPath;
              print('✅ 다운로드 완료: $name -> $localImagePath');
            } else {
              print('❌ 다운로드 실패: $name');
              localImagePath = ''; // 원본 URL 유지
            }
          } catch (e) {
            print('❌ 다운로드 에러: $name - $e');
            localImagePath = ''; // 원본 URL 유지
          }
        }
        
        // Food 객체 생성
        final food = Food(
          id: id,
          name: name,
          imageUrl: localImagePath,
        );

        if(localImagePath!=''){
          foodList.add(food);
        }
        
        // 최신 갱신일 추적
        if (updatedAt.compareTo(latestUpdatedAt) > 0) {
          latestUpdatedAt = updatedAt;
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
      
      // 마지막 갱신일 업데이트
      if (latestUpdatedAt != lastUpdatedAt) {
        await HiveHelper.instance.setLastUpdatedAt('foods', latestUpdatedAt);
        print('📅 음식 마지막 갱신일 업데이트: $latestUpdatedAt');
      }
      
      print('✅ 음식 데이터 동기화 완료: ${foodList.length}개');
    } catch (e) {
      print('❌ 음식 데이터 동기화 실패: $e');
      print('❌ 에러 상세: ${e.toString()}');
    }
  }

  static Future<void> _syncRecipes() async {
    print('📋 레시피 데이터 동기화 시작...');
    
    final lastUpdatedAt = HiveHelper.instance.getLastUpdatedAt('recipes');
    print('📅 마지막 갱신일: $lastUpdatedAt');
    
    final api = SupabaseApi();
    final recipesData = await api.getRecipes(lastUpdatedAt);
    
    if (recipesData.isEmpty) {
      print('✅ 새로운 레시피 데이터가 없습니다.');
      return;
    }
    
    print('🔄 ${recipesData.length}개의 레시피 데이터 처리 중...');
    
    // 레시피를 result_id별로 그룹핑
    final Map<int, List<int>> recipeMap = {};
    String latestUpdatedAt = lastUpdatedAt;
    
    for (final recipe in recipesData) {
      final int resultId = recipe['result_id'];
      final int requiredId = recipe['required_id'];
      final String updatedAt = recipe['updated_at'];
      
      recipeMap.putIfAbsent(resultId, () => []).add(requiredId);
      
      // 최신 갱신일 추적
      if (updatedAt.compareTo(latestUpdatedAt) > 0) {
        latestUpdatedAt = updatedAt;
      }
    }
    
    // 각 음식의 레시피 정보 업데이트
    for (final entry in recipeMap.entries) {
      final resultId = entry.key;
      final requiredIds = entry.value;
      
      await HiveHelper.instance.updateFoodRecipes(resultId, requiredIds);
      print('📝 음식 $resultId 레시피 업데이트: $requiredIds');
    }
    
    // 전역 변수에 할당
    
    // 마지막 갱신일 업데이트
    if (latestUpdatedAt != lastUpdatedAt) {
      await HiveHelper.instance.setLastUpdatedAt('recipes', latestUpdatedAt);
      print('📅 레시피 마지막 갱신일 업데이트: $latestUpdatedAt');
    }
    
    print('✅ 레시피 데이터 동기화 완료: ${recipeMap.length}개 조합');
  }

  // static Future<void> _syncInventory() async {
  //   print('🎒 인벤토리 데이터 동기화 시작...');
    
  //   final lastUpdatedAt = HiveHelper.instance.getLastUpdatedAt('inventory');
  //   print('📅 마지막 갱신일: $lastUpdatedAt');
    
  //   final api = SupabaseApi();
  //   final inventoryData = await api.getInventory(lastUpdatedAt);
    
  //   if (inventoryData.isEmpty) {
  //     print('✅ 새로운 인벤토리 데이터가 없습니다.');
  //     return;
  //   }
    
  //   print('🔄 ${inventoryData.length}개의 인벤토리 데이터 처리 중...');
    
  //   String latestUpdatedAt = lastUpdatedAt;
    
  //   for (final item in inventoryData) {
  //     final int foodId = item['food_id'];
  //     final DateTime acquiredAt = DateTime.parse(item['acquired_at']);
  //     final String updatedAt = item['updated_at'];
      
  //     // 음식의 획득 시간 업데이트
  //     await HiveHelper.instance.updateFoodAcquiredAt(foodId, acquiredAt);
  //     print('🎒 음식 $foodId 획득 시간 업데이트: $acquiredAt');
      
  //     // 최신 갱신일 추적
  //     if (updatedAt.compareTo(latestUpdatedAt) > 0) {
  //       latestUpdatedAt = updatedAt;
  //     }
  //   }
    
  //   // 마지막 갱신일 업데이트
  //   if (latestUpdatedAt != lastUpdatedAt) {
  //     await HiveHelper.instance.setLastUpdatedAt('inventory', latestUpdatedAt);
  //     print('📅 인벤토리 마지막 갱신일 업데이트: $latestUpdatedAt');
  //   }
    
  //   print('✅ 인벤토리 데이터 동기화 완료: ${inventoryData.length}개');
  // }
}

// 스크립트 실행용 main 함수
void main() async {
  await PreloadData.preloadAllData();
}
