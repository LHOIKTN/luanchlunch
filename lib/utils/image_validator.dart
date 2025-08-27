import 'dart:io';
import 'package:flutter/services.dart';
import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/data/hive/hive_helper.dart';
import 'package:launchlunch/utils/download_image.dart';
import 'package:launchlunch/utils/asset_image_manager.dart';

class ImageValidator {
  static final ImageValidator _instance = ImageValidator._internal();
  factory ImageValidator() => _instance;
  ImageValidator._internal();

  /// 모든 음식 이미지의 존재 여부를 확인하고 누락된 이미지를 복구
  Future<void> validateAndRepairImages() async {
    print('🔍 이미지 유효성 검사 및 복구 시작...');

    try {
      final allFoods = HiveHelper.instance.getAllFoods();
      print('📊 총 ${allFoods.length}개의 음식 데이터 확인 중...');

      int repairedCount = 0;
      int errorCount = 0;

      for (final food in allFoods) {
        final isValid = await _validateImage(food);
        if (!isValid) {
          print('⚠️ 이미지 누락 발견: ${food.name} (${food.imageUrl})');
          final repaired = await _repairImage(food);
          if (repaired) {
            repairedCount++;
            print('✅ 이미지 복구 완료: ${food.name}');
          } else {
            errorCount++;
            print('❌ 이미지 복구 실패: ${food.name}');
          }
        }
      }

      print('📊 이미지 검사 완료:');
      print('   - 복구된 이미지: $repairedCount개');
      print('   - 복구 실패: $errorCount개');
      print('   - 정상 이미지: ${allFoods.length - repairedCount - errorCount}개');
    } catch (e) {
      print('❌ 이미지 유효성 검사 중 오류 발생: $e');
    }
  }

  /// 개별 이미지의 유효성 확인
  Future<bool> _validateImage(Food food) async {
    try {
      if (food.imageUrl.startsWith('assets/')) {
        // Assets 이미지 확인
        return await _validateAssetImage(food.imageUrl);
      } else if (food.imageUrl.startsWith('/')) {
        // 로컬 파일 이미지 확인
        return await _validateLocalImage(food.imageUrl);
      } else {
        // Supabase URL 또는 기타 URL
        return false; // 다운로드 필요
      }
    } catch (e) {
      print('❌ 이미지 유효성 확인 실패: ${food.name} - $e');
      return false;
    }
  }

  /// Assets 이미지 유효성 확인
  Future<bool> _validateAssetImage(String imagePath) async {
    try {
      await rootBundle.load(imagePath);
      return true;
    } catch (e) {
      print('❌ Assets 이미지 로드 실패: $imagePath - $e');
      return false;
    }
  }

  /// 로컬 파일 이미지 유효성 확인
  Future<bool> _validateLocalImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        return fileSize > 0; // 파일이 존재하고 크기가 0보다 큰지 확인
      }
      return false;
    } catch (e) {
      print('❌ 로컬 파일 확인 실패: $imagePath - $e');
      return false;
    }
  }

  /// 누락된 이미지 복구
  Future<bool> _repairImage(Food food) async {
    try {
      print('🔄 이미지 복구 시작: ${food.name}');

      // 원본 이미지 URL 추출 (파일명만)
      String originalImageUrl = food.imageUrl;
      if (food.imageUrl.startsWith('/')) {
        // 로컬 파일 경로에서 파일명만 추출
        originalImageUrl = food.imageUrl.split('/').last;
      } else if (food.imageUrl.startsWith('assets/')) {
        // Assets 경로에서 파일명만 추출
        originalImageUrl = food.imageUrl.replaceFirst('assets/images/', '');
      }

      print('📝 원본 이미지 URL: $originalImageUrl');

      // Assets에 있는지 먼저 확인
      final assetImageManager = AssetImageManager();
      final assetPath = 'assets/images/$originalImageUrl';

      if (await assetImageManager.isAssetImage(assetPath)) {
        print('✅ Assets에서 이미지 발견: $assetPath');
        await _updateFoodImage(food, assetPath);
        return true;
      }

      // Assets에 없으면 Supabase에서 다운로드
      print('⬇️ Supabase에서 이미지 다운로드 시도: $originalImageUrl');
      final downloadedPath =
          await downloadAndSaveImage(originalImageUrl, forceRedownload: true);

      if (downloadedPath != null) {
        print('✅ 이미지 다운로드 성공: $downloadedPath');
        await _updateFoodImage(food, downloadedPath);
        return true;
      } else {
        print('❌ 이미지 다운로드 실패: $originalImageUrl');
        return false;
      }
    } catch (e) {
      print('❌ 이미지 복구 중 오류 발생: ${food.name} - $e');
      return false;
    }
  }

  /// 음식 데이터의 이미지 경로 업데이트
  Future<void> _updateFoodImage(Food food, String newImagePath) async {
    try {
      final updatedFood = food.copyWith(imageUrl: newImagePath);
      await HiveHelper.instance.upsertFood(updatedFood);
      print('💾 음식 데이터 업데이트 완료: ${food.name} -> $newImagePath');
    } catch (e) {
      print('❌ 음식 데이터 업데이트 실패: ${food.name} - $e');
    }
  }

  /// 특정 음식의 이미지 상태 확인
  Future<Map<String, dynamic>> checkImageStatus(Food food) async {
    final isValid = await _validateImage(food);
    final imageType = food.imageUrl.startsWith('assets/')
        ? 'assets'
        : food.imageUrl.startsWith('/')
            ? 'local'
            : 'url';

    return {
      'foodId': food.id,
      'foodName': food.name,
      'imageUrl': food.imageUrl,
      'imageType': imageType,
      'isValid': isValid,
    };
  }

  /// 모든 음식의 이미지 상태 요약
  Future<Map<String, int>> getImageStatusSummary() async {
    final allFoods = HiveHelper.instance.getAllFoods();
    int validCount = 0;
    int invalidCount = 0;
    int assetCount = 0;
    int localCount = 0;
    int urlCount = 0;

    for (final food in allFoods) {
      final isValid = await _validateImage(food);
      if (isValid) {
        validCount++;
      } else {
        invalidCount++;
      }

      if (food.imageUrl.startsWith('assets/')) {
        assetCount++;
      } else if (food.imageUrl.startsWith('/')) {
        localCount++;
      } else {
        urlCount++;
      }
    }

    return {
      'total': allFoods.length,
      'valid': validCount,
      'invalid': invalidCount,
      'assets': assetCount,
      'local': localCount,
      'url': urlCount,
    };
  }
}
