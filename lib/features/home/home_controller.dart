import 'package:launchlunch/data/hive/hive_helper.dart';
import 'package:launchlunch/models/meal.dart';
import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/data/food_data.dart';
import 'package:launchlunch/data/supabase/api_service.dart';

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
    final today = DateTime.now();
    final todayDate = _formatDate(today);
    print('📅 오늘 날짜 (한국 시간): $todayDate');

    // 오늘 날짜가 있는지 확인
    final todayMeal =
        allMeals.where((meal) => meal.lunchDate == todayDate).firstOrNull;

    if (todayMeal == null) {
      // 오늘 날짜가 없으면 빈 급식 객체 추가
      final emptyTodayMeal = DailyMeal(
        lunchDate: todayDate,
        menuList: '',
        foods: [],
        isAcquired: false,
      );
      allMeals.add(emptyTodayMeal);
      print('➕ 오늘 날짜 빈 급식 객체 추가: $todayDate');
    } else {
      print('✅ 오늘 날짜 급식 데이터 존재: $todayDate');
    }

    // lunch_date 순으로 정렬 (가장 빠른 날짜가 앞으로)
    allMeals.sort((a, b) => a.lunchDate.compareTo(b.lunchDate));
    print('🔄 날짜순 정렬 완료 (가장 빠른 날짜가 인덱스 0)');

    // 날짜 리스트 생성
    _availableDates = allMeals.map((meal) => meal.lunchDate).toList();
    print('📋 최종 날짜 리스트: $_availableDates');

    // 오늘 날짜의 인덱스 찾기
    _currentDateIndex = _availableDates.indexOf(todayDate);
    print('🎯 오늘 날짜 인덱스: $_currentDateIndex (날짜: $todayDate)');
  }

  Future<void> loadMealData() async {
    try {
      // 현재 선택된 날짜의 급식 데이터 가져오기
      if (_availableDates.isNotEmpty &&
          _currentDateIndex < _availableDates.length) {
        final targetDate = _availableDates[_currentDateIndex];
        print('🔍 조회할 날짜: $targetDate');
        final todayMeal = HiveHelper.instance.getMealByDate(targetDate);

        if (todayMeal != null) {
          print('✅ 오늘 급식 데이터 발견:');
          print('  - 메뉴: ${todayMeal.menuList}');
          print('  - 음식 ID들: ${todayMeal.foods}');
          print('  - 획득 여부: ${todayMeal.isAcquired}');
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

  // 재료 획득 기능
  Future<void> acquireIngredients() async {
    try {
      if (_todayMeal == null) {
        print('❌ 획득할 급식 데이터가 없습니다.');
        return;
      }

      print('🎁 재료 획득 시작: ${_todayMeal!.lunchDate}');

      // 현재 날짜의 음식들을 획득 상태로 변경
      final now = DateTime.now();
      final allFoods = HiveHelper.instance.getAllFoods();
      final List<Map<String, dynamic>> newlyAcquiredItems = [];

      for (final foodId in _todayMeal!.foods) {
        final food = allFoods.firstWhere(
          (f) => f.id == foodId,
          orElse: () => Food(id: foodId, name: '알 수 없는 음식', imageUrl: ''),
        );

        if (food.acquiredAt == null) {
          await HiveHelper.instance.updateFoodAcquiredAt(foodId, now);
          print('✅ 재료 획득: ${food.name} (ID: $foodId)');

          // Supabase 동기화용 데이터 준비
          newlyAcquiredItems.add({
            'food_id': foodId,
            'acquired_at': now.toIso8601String(),
          });
        } else {
          print('ℹ️ 이미 획득한 재료: ${food.name} (ID: $foodId)');
        }
      }

      // DailyMeal의 획득 상태를 true로 변경
      final updatedMeal = _todayMeal!.copyWith(isAcquired: true);
      await HiveHelper.instance.upsertMeal(updatedMeal);

      // 상태 업데이트
      _todayMeal = updatedMeal;

      print('🎁 재료 획득 완료: ${_todayMeal!.foods.length}개');

      // 새로 획득한 재료가 있으면 즉시 Supabase에 동기화 시도
      if (newlyAcquiredItems.isNotEmpty) {
        await _syncNewlyAcquiredItems(newlyAcquiredItems);
      }

      // 인벤토리 화면 데이터도 업데이트 (FoodDataManager 새로고침)
      try {
        final foodDataManager = FoodDataManager();
        await foodDataManager.loadFoodsFromHive();
        print('🔄 인벤토리 데이터 새로고침 완료');
      } catch (e) {
        print('⚠️ 인벤토리 데이터 새로고침 실패: $e');
      }
    } catch (e) {
      print('❌ 재료 획득 실패: $e');
      print('❌ 에러 상세: ${e.toString()}');
    }
  }

  /// 새로 획득한 재료들을 Supabase에 즉시 동기화
  Future<void> _syncNewlyAcquiredItems(
      List<Map<String, dynamic>> newlyAcquiredItems) async {
    try {
      final userUUID = HiveHelper.instance.getUserUUID();
      if (userUUID == null) {
        print('❌ 사용자 UUID가 없어 즉시 동기화를 건너뜁니다.');
        return;
      }

      print('🔄 새로 획득한 재료 ${newlyAcquiredItems.length}개 즉시 동기화 시작...');

      // Supabase에 업로드할 데이터 준비
      final List<Map<String, dynamic>> inventoryData = newlyAcquiredItems
          .map((item) => {
                'user_uuid': userUUID,
                'food_id': item['food_id'],
                'acquired_at': item['acquired_at'],
              })
          .toList();

      final api = SupabaseApi();
      final result = await api.insertInventory(inventoryData);

      if (result['partial_success'] == true) {
        print('✅ 즉시 동기화 성공: 추가 ${result['success_count']}개');
        if (result['duplicate_count'] > 0) {
          print('ℹ️ 이미 존재했던 재료: ${result['duplicate_count']}개');
        }
        if (result['fail_count'] > 0) {
          print('⚠️ 일부 실패: ${result['fail_count']}개 (앱 시작 시 재시도됩니다)');
        }
      } else {
        print('❌ 즉시 동기화 실패: ${result['error']} (앱 시작 시 재시도됩니다)');
      }
    } catch (e) {
      print('❌ 즉시 동기화 에러: $e (앱 시작 시 재시도됩니다)');
      // 에러가 발생해도 로컬 저장은 완료되었으므로, 앱 시작 시 syncAllAcquiredFoods가 처리
    }
  }

  void updateCurrentDateIndex(int newIndex) {
    if (newIndex >= 0 && newIndex < _availableDates.length) {
      _currentDateIndex = newIndex;
    }
  }

  String getCurrentDateString() {
    if (_availableDates.isNotEmpty &&
        _currentDateIndex < _availableDates.length) {
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
    return _getDateString(DateTime.now());
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDateString(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }
}
