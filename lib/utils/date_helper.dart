import 'package:intl/intl.dart';

class DateHelper {
  static const String _koreaTimeZone = 'Asia/Seoul';

  /// 현재 한국 날짜 가져오기
  static DateTime getCurrentDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 특정 날짜가 오늘인지 확인
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 급식 날짜가 오늘 날짜와 일치하는지 확인
  static bool isTodayMeal(String mealDate) {
    final currentDate = DateFormat('yyyy-MM-dd').format(getCurrentDate());
    return mealDate == currentDate;
  }

  /// 급식 날짜가 유효한지 확인 (오늘 또는 과거)
  static bool isValidMealDate(String mealDate) {
    final currentDate = getCurrentDate();
    return mealDate.compareTo(DateFormat('yyyy-MM-dd').format(currentDate)) <=
        0;
  }

  /// 날짜 형식 검증 (YYYY-MM-DD)
  static bool isValidDateFormat(String date) {
    try {
      DateFormat('yyyy-MM-dd').parse(date);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 한국 시간 기준으로 날짜 포맷팅
  static String formatKoreaDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// 급식 날짜를 한국 시간 기준으로 파싱
  static DateTime parseMealDate(String mealDate) {
    return DateFormat('yyyy-MM-dd').parse(mealDate);
  }

  /// 디버그용: 현재 한국 시간 정보 출력
  static void printCurrentKoreaTime() {
    final now = DateTime.now();
    final koreaTime = getCurrentDate();
    print('🌍 현재 시간 정보:');
    print('  - 로컬 시간: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(now)}');
    print('  - 한국 시간: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(koreaTime)}');
    print('  - 한국 날짜: ${DateFormat('yyyy-MM-dd').format(koreaTime)}');
  }

  /// 테스트용: 현재 날짜 또는 테스트 날짜 반환
  static String getCurrentOrTestDate() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }
}
