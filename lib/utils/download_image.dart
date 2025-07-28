import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final supabaseStorageUrl = dotenv.env['SUPABASE_BUCKET'];

Future<String?> downloadAndSaveImage(String imageUrl, {bool forceRedownload = false}) async {
  try {
    print('🖼️ 이미지 다운로드 시작: $imageUrl (강제재다운로드: $forceRedownload)');
    
    final dir = await getApplicationDocumentsDirectory();
    final filePath = p.join(dir.path, imageUrl);
    final file = File(filePath);
    
    // 기존 파일 확인
    if (await file.exists() && !forceRedownload) {
      print('✅ 기존 이미지 파일 사용: $filePath');
      print('✅ 파일 크기: ${await file.length()} bytes');
      return filePath;
    }
    
    if (forceRedownload && await file.exists()) {
      print('🔄 기존 이미지 파일 삭제 후 재다운로드: $filePath');
      await file.delete();
    }
    
    print('🖼️ Supabase에서 새로 다운로드: $supabaseStorageUrl/$imageUrl');

    // 개발 환경용 SSL 검증 우회 (프로덕션에서는 제거)
    final client = http.Client();

    // SSL 검증 우회 (개발 환경에서만)
    // 원본 URL 사용
    final response = await client.get(
      Uri.parse('$supabaseStorageUrl/$imageUrl'),
    );

    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);

      print('✅ 이미지 다운로드 완료: $filePath');
      print('✅ 파일 존재 확인: ${await file.exists()}');
      print('✅ 파일 크기: ${await file.length()} bytes');

      return filePath;
    } else {
      print('❌ HTTP 에러: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('❌ 이미지 다운로드 에러: $e');
    return null;
  }
}
