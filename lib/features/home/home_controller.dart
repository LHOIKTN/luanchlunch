import 'package:launchlunch/data/hive/hive_helper.dart';
import 'package:launchlunch/models/meal.dart';
import 'package:launchlunch/models/food.dart';

class HomeController {
  List<String> _availableDates = [];
  int _currentDateIndex = 0;
  DailyMeal? _todayMeal;
  List<Food> _availableFoods = [];

  List<String> get availableDates => _availableDates;
  int get currentDateIndex => _currentDateIndex;
  DailyMeal? get todayMeal => _todayMeal;
  List<Food> get availableFoods => _availableFoods;

  void loadAvailableDates() {
    // Hive에서 모든 급식 데이터를 리스트로 불러오기
    final allMeals = HiveHelper.instance.getAllMeals();
    print('📊 초기 Hive 급식 데이터: ${allMeals.length}개');

    // 실제 오늘 날짜 (한국 시간)
    final today = DateTime.now().toUtc().add(const Duration(hours: 9));
    final todayDate = _formatDate(today);
    print('📅 오늘 날짜 (한국 시간): $todayDate');

    // 오늘 날짜가 있는지 확인
    final todayMeal = allMeals.where((meal) => meal.mealDate == todayDate).firstOrNull;

    if (todayMeal == null) {
      // 오늘 날짜가 없으면 빈 급식 객체 추가
      final emptyTodayMeal = DailyMeal(
        mealDate: todayDate,
        menus: [],
        foods: [],
      );
      allMeals.add(emptyTodayMeal);
      print('➕ 오늘 날짜 빈 급식 객체 추가: $todayDate');
    } else {
      print('✅ 오늘 날짜 급식 데이터 존재: $todayDate');
    }

    // meal_date 순으로 정렬 (가장 빠른 날짜가 앞으로)
    allMeals.sort((a, b) => a.mealDate.compareTo(b.mealDate));
    print('🔄 날짜순 정렬 완료 (가장 빠른 날짜가 인덱스 0)');

    // 날짜 리스트 생성
    _availableDates = allMeals.map((meal) => meal.mealDate).toList();
    print('📋 최종 날짜 리스트: $_availableDates');

    // 오늘 날짜의 인덱스 찾기
    _currentDateIndex = _availableDates.indexOf(todayDate);
    print('🎯 오늘 날짜 인덱스: $_currentDateIndex (날짜: $todayDate)');
  }

  Future<void> loadMealData() async {
    try {
      // 현재 선택된 날짜의 급식 데이터 가져오기
      if (_availableDates.isNotEmpty && _currentDateIndex < _availableDates.length) {
        final targetDate = _availableDates[_currentDateIndex];
        print('🔍 조회할 날짜: $targetDate');
        final todayMeal = HiveHelper.instance.getMealByDate(targetDate);

        if (todayMeal != null) {
          print('✅ 오늘 급식 데이터 발견:');
          print('  - 메뉴: ${todayMeal.menus}');
          print('  - 음식 ID들: ${todayMeal.foods}');
        } else {
          print('❌ 오늘 급식 데이터 없음');
        }

        // 획득 가능한 재료들 가져오기
        final allFoods = HiveHelper.instance.getAllFoods();
        print('🍽️ 전체 음식 데이터: ${allFoods.length}개');

        final availableFoods = <Food>[];

        if (todayMeal != null) {
          print('🔍 급식 음식 ID들과 획득 가능한 음식 매칭:');
          // 해당 날짜 급식에 포함된 모든 음식들을 추가 (획득 여부와 관계없이)
          for (final foodId in todayMeal.foods) {
            print('  - 음식 ID $foodId 검색 중...');
            final food = allFoods.firstWhere(
              (f) => f.id == foodId,
              orElse: () {
                print('    ❌ ID $foodId 음식을 찾을 수 없음');
                return Food(id: foodId, name: '알 수 없는 음식', imageUrl: '');
              },
            );

            print('    ✅ 음식 발견: ${food.name} (획득일: ${food.acquiredAt})');
            availableFoods.add(food);
          }
        }

        print('📋 최종 availableFoods: ${availableFoods.length}개');

        _todayMeal = todayMeal;
        _availableFoods = availableFoods;
      }
    } catch (e) {
      print('❌ 급식 데이터 로드 실패: $e');
      print('❌ 에러 상세: ${e.toString()}');
    }
  }

  void updateCurrentDateIndex(int newIndex) {
    if (newIndex >= 0 && newIndex < _availableDates.length) {
      _currentDateIndex = newIndex;
    }
  }

  String getCurrentDateString() {
    if (_availableDates.isNotEmpty && _currentDateIndex < _availableDates.length) {
      final dateStr = _availableDates[_currentDateIndex];
      final dateParts = dateStr.split('-');
      if (dateParts.length == 3) {
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        final date = DateTime(year, month, day);
        return _getDateString(date);
      }
    }
    return _getDateString(DateTime.now().toUtc().add(const Duration(hours: 9)));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDateString(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }
} 