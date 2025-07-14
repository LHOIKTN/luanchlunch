import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recipes.dart';
import '../globals.dart';
import '../utils/recipe_utils.dart';

class PreloadData {
  static Future<void> preloadAllData() async {
    print('🔄 데이터 프리로드 시작...');
    
    try {
      // 1. 환경변수 로드
      await dotenv.load(fileName: '.env');
      
      // 2. Supabase 초기화
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );
      
      // 3. 레시피 데이터 조회 및 변환
      await _preloadRecipes();
      
      // 4. 이미지 다운로드 (필요시)
      await _preloadImages();
      
      print('✅ 데이터 프리로드 완료!');
    } catch (e) {
      print('❌ 데이터 프리로드 실패: $e');
    }
  }
  
  static Future<void> _preloadRecipes() async {
    print('📋 레시피 데이터 조회 중...');
    
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('recipes')
        .select('*')
        .execute();
    
    if (response.error != null) {
      throw Exception('레시피 조회 실패: ${response.error!.message}');
    }
    
    final List<dynamic> recipesData = response.data as List<dynamic>;
    final List<Recipes> recipesList = recipesData
        .map((data) => Recipes.fromMap(Map<String, dynamic>.from(data)))
        .toList();
    
    // 전역 변수에 할당
    globalRecipeMap = RecipeUtils.groupByResult(recipesList);
    
    print('📋 레시피 데이터 로드 완료: ${recipesList.length}개');
    print('📋 레시피 맵: $globalRecipeMap');
  }
  
  static Future<void> _preloadImages() async {
    print('🖼️ 이미지 다운로드 중...');
    
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('foods')
        .select('image_url')
        .execute();
    
    if (response.error != null) {
      throw Exception('이미지 URL 조회 실패: ${response.error!.message}');
    }
    
    final List<dynamic> foodsData = response.data as List<dynamic>;
    final List<String> imageUrls = foodsData
        .map((data) => data['image_url'] as String)
        .where((url) => url.isNotEmpty)
        .toList();
    
    // assets/images 디렉토리 생성
    final assetsDir = Directory('assets/images');
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    
    // 이미지 다운로드 (예시)
    for (int i = 0; i < imageUrls.length; i++) {
      final url = imageUrls[i];
      final fileName = 'food_${i + 1}.webp';
      final filePath = 'assets/images/$fileName';
      
      try {
        // 실제 다운로드 로직은 http 패키지 사용
        print('🖼️ 다운로드 중: $fileName');
        // await _downloadImage(url, filePath);
      } catch (e) {
        print('⚠️ 이미지 다운로드 실패: $fileName - $e');
      }
    }
    
    print('🖼️ 이미지 다운로드 완료');
  }
  
  // static Future<void> _downloadImage(String url, String filePath) async {
  //   // http 패키지로 이미지 다운로드 구현
  //   // 실제 구현은 필요에 따라 추가
  // }
}

// 스크립트 실행용 main 함수
void main() async {
  await PreloadData.preloadAllData();
}
