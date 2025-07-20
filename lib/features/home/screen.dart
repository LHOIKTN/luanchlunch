import 'package:flutter/material.dart';
import 'package:launchlunch/features/inventory/screen.dart';
import 'package:launchlunch/data/hive/hive_helper.dart';
import 'package:launchlunch/models/meal.dart';
import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/widgets/common/food_chip.dart';
import 'package:launchlunch/features/profile/screen.dart';

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
    const _RankingTab(),
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
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
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
  late PageController _pageController;
  late DateTime _currentDate;
  int _currentPage = 1000; // 중앙에서 시작하기 위한 큰 값

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _currentDate = DateTime.now().add(Duration(days: page - _currentPage));
    });
  }

  String _getDateString(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final date =
                DateTime.now().add(Duration(days: index - _currentPage));
            return _DailyMenuPage(date: date);
          },
        ),
      ),
    );
  }
}

class _DailyMenuPage extends StatefulWidget {
  final DateTime date;

  const _DailyMenuPage({required this.date});

  @override
  State<_DailyMenuPage> createState() => _DailyMenuPageState();
}

class _DailyMenuPageState extends State<_DailyMenuPage> {
  DailyMeal? _todayMeal;
  List<Food> _availableFoods = [];
  bool _isLoading = true;
  List<String> _availableDates = [];
  int _currentDateIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAvailableDates();
    _loadMealData();
  }

  void _loadAvailableDates() {
    // Hive에서 사용 가능한 급식 날짜들 가져오기
    final allMeals = HiveHelper.instance.getAllMeals();
    _availableDates = allMeals.map((meal) => meal.mealDate).toList();
    _availableDates.sort((a, b) => b.compareTo(a)); // 날짜순 정렬 (최신 날짜가 앞으로)

    // 오늘 날짜가 있는지 확인하고 인덱스 설정
    final todayDate =
        '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';
    final todayIndex = _availableDates.indexOf(todayDate);
    _currentDateIndex = todayIndex >= 0 ? todayIndex : 0;
  }

  Future<void> _loadMealData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 현재 선택된 날짜의 급식 데이터 가져오기
      String targetDate;
      if (_availableDates.isNotEmpty &&
          _currentDateIndex < _availableDates.length) {
        targetDate = _availableDates[_currentDateIndex];
      } else {
        targetDate =
            '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';
      }

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
        print('  * ID: ${food.id}, 이름: ${food.name}, 획득일: ${food.acquiredAt}');
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
    } catch (e) {
      print('❌ 급식 데이터 로드 실패: $e');
      print('❌ 에러 상세: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSwipeLeft() {
    if (_currentDateIndex > 0) {
      setState(() {
        _currentDateIndex--;
      });
      _loadMealData();
    }
  }

  void _onSwipeRight() {
    if (_currentDateIndex < _availableDates.length - 1) {
      setState(() {
        _currentDateIndex++;
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
        return _getDateString(date);
      }
    }
    return _getDateString(widget.date);
  }

  String _getDateString(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  // 오른쪽으로 스와이프 (이전 날짜)
                  _onSwipeRight();
                } else if (details.primaryVelocity! < 0) {
                  // 왼쪽으로 스와이프 (다음 날짜)
                  _onSwipeLeft();
                }
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 날짜 표시
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCurrentDateString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.date.year}년 ${widget.date.month}월 ${widget.date.day}일',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 오늘의 급식 정보
                    const Text(
                      '급식 메뉴',
                      style: TextStyle(
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.restaurant,
                                          color: Color(0xFF4CAF50), size: 20),
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
                                      color: Color(0xFF4CAF50),
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
                          '오늘은 급식이 없습니다.',
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
              ),
            ),
    );
  }
}

// 랭킹 탭
class _RankingTab extends StatelessWidget {
  const _RankingTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '랭킹',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 80,
              color: Color(0xFF4CAF50),
            ),
            SizedBox(height: 16),
            Text(
              '랭킹 기능 준비 중입니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '곧 만나보실 수 있어요!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
