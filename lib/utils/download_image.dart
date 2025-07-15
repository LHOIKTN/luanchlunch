import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'asset_image_manager.dart';

final supabaseStorageUrl = dotenv.env['SUPABASE_BUCKET'];

Future<String?> downloadAndSaveImage(String fileName) async {
  // assets에 있는 이미지는 다운로드하지 않음
  final assetImageManager = AssetImageManager();
  final assetImagePath = 'assets/images/$fileName';
  
  if (await assetImageManager.isAssetImage(assetImagePath)) {
    print('🖼️ Assets 이미지이므로 다운로드 건너뜀: $fileName');
    return assetImagePath;
  }
  try {
    print('🖼️ 이미지 다운로드 시작: $fileName');
    print('🖼️ Supabase URL: $supabaseStorageUrl');
    
    // 개발 환경용 SSL 검증 우회 (프로덕션에서는 제거)
    final client = http.Client();
    
    // SSL 검증 우회 (개발 환경에서만)
    if (supabaseStorageUrl?.contains('https') == true) {
      // HTTPS URL을 HTTP로 변경 (개발 환경용)
      final httpUrl = supabaseStorageUrl!.replaceFirst('https://', 'http://');
      final response = await client.get(
        Uri.parse('$httpUrl/$fileName'),
        headers: {
          'User-Agent': 'Flutter App',
        },
      );
      
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = p.join(dir.path, fileName);
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        print('✅ 이미지 다운로드 완료: $filePath');
        print('✅ 파일 존재 확인: ${await file.exists()}');
        print('✅ 파일 크기: ${await file.length()} bytes');
        
        return filePath;
      } else {
        print('❌ HTTP 에러: ${response.statusCode}');
        return null;
      }
    } else {
      // 원본 URL 사용
      final response = await client.get(
        Uri.parse('$supabaseStorageUrl/$fileName'),
        headers: {
          'User-Agent': 'Flutter App',
        },
      );
      
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = p.join(dir.path, fileName);
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        
        print('✅ 이미지 다운로드 완료: $filePath');
        print('✅ 파일 존재 확인: ${await file.exists()}');
        print('✅ 파일 크기: ${await file.length()} bytes');
        
        return filePath;
      } else {
        print('❌ HTTP 에러: ${response.statusCode}');
        return null;
      }
    }
    
  } catch (e) {
    print('❌ 이미지 다운로드 에러: $e');
    return null;
  }
}
