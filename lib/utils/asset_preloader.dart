import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class AssetPreloader {
  static Future<void> downloadImagesToAssets() async {
    print('🖼️ Assets 이미지 다운로드 시작...');
    
    try {
      // 1. 환경변수 로드
      await dotenv.load(fileName: '.env');
      
      // 2. Supabase 초기화
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );
      
      // 3. 이미지 URL 조회
      await _downloadFoodImages();
      
      print('✅ Assets 이미지 다운로드 완료!');
    } catch (e) {
      print('❌ Assets 이미지 다운로드 실패: $e');
    }
  }
  
  static Future<void> _downloadFoodImages() async {
    print('📋 음식 이미지 URL 조회 중...');
    
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('foods')
        .select('id, name, image_url')
        .execute();
    
    if (response.error != null) {
      throw Exception('음식 데이터 조회 실패: ${response.error!.message}');
    }
    
    final List<dynamic> foodsData = response.data as List<dynamic>;
    
    // assets/images 디렉토리 생성
    final assetsDir = Directory('assets/images');
    if (!await assetsDir.exists()) {
      await assetsDir.create(recursive: true);
    }
    
    print('🖼️ ${foodsData.length}개의 이미지 다운로드 시작...');
    
    // 이미지 다운로드
    for (final foodData in foodsData) {
      final int id = foodData['id'];
      final String name = foodData['name'];
      final String imageUrl = foodData['image_url'];
      
      if (imageUrl.isEmpty) {
        print('⚠️ 이미지 URL 없음: $name (ID: $id)');
        continue;
      }
      
      try {
        // 파일명 생성 (name을 기반으로, 특수문자 제거)
        final fileName = _generateFileName(name);
        final filePath = 'assets/images/$fileName';
        
        // 이미 존재하는지 확인
        final file = File(filePath);
        if (await file.exists()) {
          print('✅ 이미 존재: $fileName');
          continue;
        }
        
        // 이미지 다운로드
        print('⬇️ 다운로드 중: $fileName');
        await _downloadImage(imageUrl, filePath);
        print('✅ 다운로드 완료: $fileName');
        
      } catch (e) {
        print('❌ 다운로드 실패: $name (ID: $id) - $e');
      }
    }
    
    print('🖼️ 이미지 다운로드 작업 완료');
  }
  
  static String _generateFileName(String name) {
    // 한글 이름을 영문 파일명으로 변환 (간단한 매핑)
    final nameMap = {
      '쌀': 'rice',
      '소금': 'salt',
      '설탕': 'sugar',
      '마늘': 'garlic',
      '대파': 'green_onion',
      '참기름': 'sesame_oil',
      '고추': 'gochu',
      '고춧가루': 'gochugaru',
      '콩나물': 'bean_sprout',
      '블루베리': 'blueberry',
      '닭고기': 'chicken',
      '알타리무': 'ponytail_radish',
      '양상추': 'lettuce',
      '배추': 'napa_cabbage',
      '미역': 'seaweed',
      '블루베리밥': 'blueberry_rice',
      '감자': 'potato',
    };
    
    final englishName = nameMap[name] ?? name.toLowerCase().replaceAll(' ', '_');
    return '$englishName.webp';
  }
  
  static Future<void> _downloadImage(String url, String filePath) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('이미지 다운로드 실패: $e');
    }
  }
}

// 독립 실행용 main 함수
void main() async {
  await AssetPreloader.downloadImagesToAssets();
} 