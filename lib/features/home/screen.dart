import 'package:flutter/material.dart';
import 'package:launchlunch/features/inventory/screen.dart';
import 'package:launchlunch/data/hive/hive_helper.dart';
import 'package:launchlunch/models/meal.dart';
import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/widgets/common/food_chip.dart';
import 'package:launchlunch/features/profile/screen.dart';
import 'package:launchlunch/features/ranking/screen.dart';
import 'package:launchlunch/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const FoodGridScreen(),
    const RankingScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: '조합'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: '랭킹'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
        ],
      ),
    );
  }
}

// 홈 탭
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: const _DailyMenuPage(),
      ),
    );
  }
}

class _DailyMenuPage extends StatefulWidget {
  const _DailyMenuPage();

  @override
  State<_DailyMenuPage> createState() => _DailyMenuPageState();
}

class _DailyMenuPageState extends State<_DailyMenuPage> {
  DailyMeal? _todayMeal;
  List<Food> _availableFoods = [];
  bool _isLoading = true;
  List<String> _availableDates = [];
  int _currentDateIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _loadAvailableDates();
    _loadMealData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadAvailableDates() {
    // Hive에서 모든 급식 데이터를 리스트로 불러오기
    final allMeals = HiveHelper.instance.getAllMeals();
    print('📊 초기 Hive 급식 데이터: ${allMeals.length}개');
    for (final meal in allMeals) {
      print(
          '  - ${meal.mealDate}: 메뉴 ${meal.menus.length}개, 음식 ${meal.foods.length}개');
    }

    // 실제 오늘 날짜 (한국 시간)
    final today =
        DateTime.now().toUtc().add(const Duration(hours: 9)); // UTC+9 (한국 시간)
    final todayDate =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    print('📅 오늘 날짜 (한국 시간): $todayDate');

    // 오늘 날짜가 있는지 확인
    final todayMeal =
        allMeals.where((meal) => meal.mealDate == todayDate).firstOrNull;

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
    
    // PageController 초기화
    if (_availableDates.isNotEmpty) {
      _pageController = PageController(initialPage: _currentDateIndex);
    }
  }

  Future<void> _loadMealData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 선택된 날짜의 급식 데이터 가져오기
      if (_availableDates.isNotEmpty &&
          _currentDateIndex < _availableDates.length) {
        final targetDate = _availableDates[_currentDateIndex];
        print('🔍 조회할 날짜: $targetDate');
        final todayMeal = HiveHelper.instance.getMealByDate(targetDate);

        // Hive 데이터 디버깅
        print('📊 Hive 데이터 확인:');
        final allMeals = HiveHelper.instance.getAllMeals();
        print('  - 전체 급식 데이터: ${allMeals.length}개');
        for (final meal in allMeals.take(3)) {
          print(
              '    * ${meal.mealDate}: 메뉴 ${meal.menus.length}개, 음식 ${meal.foods.length}개');
        }

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

        // 획득한 음식들 확인
        final acquiredFoods =
            allFoods.where((food) => food.acquiredAt != null).toList();
        print('✅ 획득한 음식들: ${acquiredFoods.length}개');
        for (final food in acquiredFoods.take(5)) {
          print(
              '  * ID: ${food.id}, 이름: ${food.name}, 획득일: ${food.acquiredAt}');
        }

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

            // 획득 여부와 관계없이 모든 음식 추가
            availableFoods.add(food);
            if (food.acquiredAt != null) {
              print('    🎉 이미 획득한 음식');
            } else {
              print('    ⚠️ 아직 획득하지 않은 음식 (획득 가능)');
            }
          }
        }

        print('📋 최종 availableFoods: ${availableFoods.length}개');
        for (final food in availableFoods) {
          print('  - ${food.name} (ID: ${food.id})');
        }

        setState(() {
          _todayMeal = todayMeal;
          _availableFoods = availableFoods;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 급식 데이터 로드 실패: $e');
      print('❌ 에러 상세: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPageChanged(int page) {
    if (page != _currentDateIndex && page >= 0 && page < _availableDates.length) {
      setState(() {
        _currentDateIndex = page;
      });
      _loadMealData();
    }
  }

  String _getCurrentDateString() {
    if (_availableDates.isNotEmpty &&
        _currentDateIndex < _availableDates.length) {
      final dateStr = _availableDates[_currentDateIndex];
      final dateParts = dateStr.split('-');
      if (dateParts.length == 3) {
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        final date = DateTime(year, month, day);
        final result = _getDateString(date);
        print(
            '📱 화면에 표시되는 날짜: $result (원본: $dateStr, 인덱스: $_currentDateIndex)');
        return result;
      }
    }
    final fallback =
        _getDateString(DateTime.now().toUtc().add(const Duration(hours: 9)));
    print('⚠️ 화면에 표시되는 날짜 (fallback, 한국 시간): $fallback');
    return fallback;
  }

  String _getDateString(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_availableDates.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
          child: Text(
            '사용 가능한 날짜가 없습니다.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: _availableDates.length,
        itemBuilder: (context, index) {
          // 현재 페이지의 데이터를 로드
          if (index == _currentDateIndex) {
            return _buildDailyMenuContent();
          } else {
            // 다른 페이지는 로딩 상태로 표시
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildDailyMenuContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 오늘의 급식 정보
          Text(
            '${_getCurrentDateString()} 급식 메뉴',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (_todayMeal != null && _todayMeal!.menus.isNotEmpty) ...[
            // 메뉴 리스트
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ..._todayMeal!.menus.map((menu) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.restaurant,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                menu,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 획득 가능한 재료 섹션
            const Text(
              '획득 가능한 재료',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (_availableFoods.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_availableFoods.length}개의 재료',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${_availableFoods.where((f) => f.acquiredAt != null).length}개 획득)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableFoods
                          .map((food) => FoodChip(food: food))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  '아직 획득한 재료가 없습니다.\n조합 탭에서 재료를 획득해보세요!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ] else ...[
            // 급식 정보가 없는 경우
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                '이 날짜에는 급식이 없습니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
