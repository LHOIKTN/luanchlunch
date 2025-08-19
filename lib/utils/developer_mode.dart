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

  /// 개발자 모드 비활성화
  static Future<void> disable() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDeveloperMode, false);
    print('🔧 개발자 모드 비활성화');
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
    final lastTapTime = prefs.getInt(_keyLastTapTime);
    final currentTapCount = prefs.getInt(_keyTapCount) ?? 0;

    // 마지막 탭으로부터 3초가 지났으면 카운트 리셋
    if (lastTapTime != null) {
      final lastTap = DateTime.fromMillisecondsSinceEpoch(lastTapTime);
      if (now.difference(lastTap) > _tapTimeout) {
        await prefs.setInt(_keyTapCount, 1);
        await prefs.setInt(_keyLastTapTime, now.millisecondsSinceEpoch);
        return false;
      }
    }

    // 탭 카운트 증가
    final newTapCount = currentTapCount + 1;
    await prefs.setInt(_keyTapCount, newTapCount);
    await prefs.setInt(_keyLastTapTime, now.millisecondsSinceEpoch);

    print('👆 닉네임 탭: $newTapCount/$_requiredTaps');

    // 7번 탭했으면 개발자 모드 토글
    if (newTapCount >= _requiredTaps) {
      await toggle();
      await prefs.setInt(_keyTapCount, 0); // 카운트 리셋
      return true;
    }

    return false;
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
