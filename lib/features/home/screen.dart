import 'package:flutter/material.dart';
import 'package:launchlunch/features/inventory/screen.dart';
import 'package:launchlunch/features/profile/screen.dart';
import 'package:launchlunch/features/ranking/screen.dart';
import 'package:launchlunch/theme/app_colors.dart';
import 'package:launchlunch/features/home/home_controller.dart';
import 'package:launchlunch/features/home/widgets/menu_list_card.dart';
import 'package:launchlunch/features/home/widgets/ingredients_section.dart';

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
  bool _isLoading = true;
  late PageController _pageController;
  late HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _initializeData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    _controller.loadAvailableDates();
    
    if (_controller.availableDates.isNotEmpty) {
      _pageController = PageController(initialPage: _controller.currentDateIndex);
      await _loadMealData();
    }
  }



  Future<void> _loadMealData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _controller.loadMealData();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 급식 데이터 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPageChanged(int page) {
    if (page != _controller.currentDateIndex && 
        page >= 0 && 
        page < _controller.availableDates.length) {
      _controller.updateCurrentDateIndex(page);
      _loadMealData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_controller.availableDates.isEmpty) {
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
        itemCount: _controller.availableDates.length,
        itemBuilder: (context, index) {
          // 현재 페이지의 데이터를 로드
          if (index == _controller.currentDateIndex) {
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
            '${_controller.getCurrentDateString()} 급식 메뉴',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (_controller.todayMeal != null && _controller.todayMeal!.menus.isNotEmpty) ...[
            // 메뉴 리스트
            MenuListCard(meal: _controller.todayMeal!),

            const SizedBox(height: 20),

            // 획득 가능한 재료 섹션
            IngredientsSection(availableFoods: _controller.availableFoods),
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
