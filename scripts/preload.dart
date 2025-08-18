import 'dart:io';
import '../lib/utils/preload.dart';

void main() async {
  print('🚀 빌드 전 데이터 프리로드 시작...');

  try {
    final preloader = PreloadData();
    await preloader.preloadAllData();
    print('✅ 프리로드 완료! 이제 빌드할 수 있습니다.');
    // exit(0) 제거 - iOS에서 비정상 종료 방지
  } catch (e) {
    print('❌ 프리로드 실패: $e');
    // exit(1) 제거 - iOS에서 비정상 종료 방지
    // 대신 예외를 다시 던져서 스크립트가 실패했음을 알림
    rethrow;
  }
}
