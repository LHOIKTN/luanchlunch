import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final supabaseStorageUrl = dotenv.env['SUPABASE_BUCKET'];

Future<String?> downloadAndSaveImage(String fileName) async {
  try {
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
        return filePath;
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
        return filePath;
      }
    }
    
    return null;
  } catch (e) {
    print('이미지 다운로드 에러: $e');
    return null;
  }
}
