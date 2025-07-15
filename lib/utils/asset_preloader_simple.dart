import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AssetPreloaderSimple {
  static Future<void> downloadImagesToAssets() async {
    print('🖼️ Assets 이미지 다운로드 시작...');
    
    try {
      // 환경변수 직접 읽기 (dotenv 대신)
      final envFile = File('.env');
      if (!await envFile.exists()) {
        throw Exception('.env 파일이 없습니다.');
      }
      
      final envContent = await envFile.readAsString();
      print(envContent);
      final envMap = <String, String>{};
      
      for (final line in envContent.split('\n')) {
        if (line.contains('=')) {
          final parts = line.split('=');
          if (parts.length >= 2) {
            envMap[parts[0].trim()] = parts[1].trim();
          }
        }
      }
      
      final supabaseUrl = envMap['SUPABASE_URL'];
      final supabaseKey = envMap['SUPABASE_KEY'];
      
      if (supabaseUrl == null || supabaseKey == null) {
        throw Exception('SUPABASE_URL 또는 SUPABASE_ANON_KEY가 .env에 없습니다.');
      }
      
      // Supabase API 직접 호출
      await _downloadFoodImages(supabaseUrl, supabaseKey);
      
      print('✅ Assets 이미지 다운로드 완료!');
    } catch (e) {
      print('❌ Assets 이미지 다운로드 실패: $e');
    }
  }
  
  static Future<void> _downloadFoodImages(String supabaseUrl, String supabaseKey) async {
    print('📋 음식 이미지 URL 조회 중...');
    
    // Supabase REST API 직접 호출
    final response = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/foods?select=id,name,image_url'),
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode != 200) {
      throw Exception('음식 데이터 조회 실패: ${response.statusCode}');
    }
    
    final List<dynamic> foodsData = jsonDecode(response.body);
    
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
        final fileName = imageUrl.replaceAll(' ', '_').replaceAll('png','webp');
        final filePath = 'assets/images/$fileName';
        print(filePath);
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
  await AssetPreloaderSimple.downloadImagesToAssets();
} 