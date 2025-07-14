import 'dart:io';
import '../lib/utils/preload.dart';

void main() async {
  print('🚀 빌드 전 데이터 프리로드 시작...');
  
  try {
    await PreloadData.preloadAllData();
    print('✅ 프리로드 완료! 이제 빌드할 수 있습니다.');
    exit(0);
  } catch (e) {
    print('❌ 프리로드 실패: $e');
    exit(1);
  }
} 