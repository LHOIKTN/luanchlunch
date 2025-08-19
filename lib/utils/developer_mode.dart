import 'package:shared_preferences/shared_preferences.dart';
import 'package:launchlunch/data/hive/hive_helper.dart';

class DeveloperMode {
  static const String _keyDeveloperMode = 'developer_mode_enabled';
  static const String _keyTapCount = 'nickname_tap_count';
  static const String _keyLastTapTime = 'last_tap_time';

  static const int _requiredTaps = 7;
  static const Duration _tapTimeout = Duration(seconds: 3); // 3초 내에 7번 탭해야 함

  /// 개발자 모드 활성화 여부 확인
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDeveloperMode) ?? false;
  }

  /// 개발자 모드 토글
  static Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    final currentState = prefs.getBool(_keyDeveloperMode) ?? false;
    final newState = !currentState;

    await prefs.setBool(_keyDeveloperMode, newState);
    print('🔧 개발자 모드 ${!currentState ? '활성화' : '비활성화'}');
  }

  /// 닉네임이 "gattaca"인지 확인
  static Future<bool> isGattacaNickname() async {
    final nickname = await HiveHelper.instance.getNickname();
    return nickname?.toLowerCase() == 'gattaca';
  }

  /// 닉네임 텍스트 탭 처리
  static Future<bool> handleNicknameTap() async {
    // 닉네임이 "gattaca"가 아니면 조용히 아무것도 하지 않음
    if (!await isGattacaNickname()) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    final lastTapTimeString = prefs.getString(_keyLastTapTime);
    final lastTapTime =
        lastTapTimeString != null ? DateTime.parse(lastTapTimeString) : null;
    int tapCount = prefs.getInt(_keyTapCount) ?? 0;

    if (lastTapTime == null || now.difference(lastTapTime) > _tapTimeout) {
      // 타임아웃이 지났거나 첫 탭이면 카운트 초기화
      tapCount = 1;
    } else {
      // 타임아웃 내에 탭했으면 카운트 증가
      tapCount++;
    }

    await prefs.setString(_keyLastTapTime, now.toIso8601String());
    await prefs.setInt(_keyTapCount, tapCount);

    print('개발자 모드 탭: $tapCount회');

    if (tapCount >= _requiredTaps) {
      await prefs.setInt(_keyTapCount, 0); // 카운트 초기화
      await prefs.remove(_keyLastTapTime); // 마지막 탭 시간 초기화
      await toggle(); // 개발자 모드 토글
      return true; // 상태 변경됨
    }
    return false; // 상태 변경 없음
  }

  /// 개발자 모드 비활성화 및 관련 데이터 삭제
  static Future<void> disable() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 개발자 모드 비활성화
      await prefs.setBool(_keyDeveloperMode, false);

      // 탭 관련 데이터 삭제
      await prefs.remove(_keyLastTapTime);
      await prefs.remove(_keyTapCount);

      print('🔧 개발자 모드 완전 비활성화 및 데이터 삭제 완료');
    } catch (e) {
      print('❌ 개발자 모드 비활성화 실패: $e');
    }
  }

  /// 탭 카운트 리셋
  static Future<void> resetTapCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTapCount, 0);
    await prefs.setInt(_keyLastTapTime, 0);
  }

  /// 현재 탭 카운트 확인
  static Future<int> getCurrentTapCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTapCount) ?? 0;
  }

  /// 개발자 모드 상태 출력
  static Future<void> printDeveloperModeStatus() async {
    final isEnabled = await DeveloperMode.isEnabled();
    final tapCount = await DeveloperMode.getCurrentTapCount();
    print('🔧 개발자 모드 상태:');
    print('  - 활성화: $isEnabled');
    print('  - 현재 탭 카운트: $tapCount/$_requiredTaps');
  }
}
