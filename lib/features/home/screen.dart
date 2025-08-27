import 'package:flutter/material.dart';
import 'package:launchlunch/features/inventory/screen.dart';
import 'package:launchlunch/features/profile/screen.dart';
import 'package:launchlunch/features/ranking/screen.dart';
import 'package:launchlunch/theme/app_colors.dart';
import 'package:launchlunch/features/home/home_controller.dart';
import 'package:launchlunch/features/home/widgets/menu_list_card.dart';
import 'package:launchlunch/features/home/widgets/ingredients_section.dart';
import 'package:launchlunch/features/home/widgets/ingredient_acquisition_card.dart';
import 'package:launchlunch/utils/developer_mode.dart';
import 'package:launchlunch/utils/device_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const FoodGridScreen(),
    const RankingScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아올 때만 데이터 새로고침
      print('🔄 앱이 포그라운드로 돌아옴 - 전체 데이터 새로고침 트리거');
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            selectedLabelStyle: TextStyle(
              fontSize: DeviceHelper.getScaledFontSize(context, 12.0),
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: DeviceHelper.getScaledFontSize(context, 12.0),
            ),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          iconSize: DeviceHelper.getScaledIconSize(context, 24.0),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory), label: '조합'),
            BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events), label: '랭킹'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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

class _DailyMenuPageState extends State<_DailyMenuPage>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  late PageController _pageController;
  late HomeController _controller;
  bool _isDeveloperModeEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = HomeController();
    _initializeData();
    _loadDeveloperModeStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아올 때만 데이터 새로고침
      print('🔄 앱이 포그라운드로 돌아옴 - 홈 데이터 새로고침');
      _refreshDataIfNeeded();
      _loadDeveloperModeStatus();
    }
  }

  /// 필요한 경우에만 데이터를 새로고침
  void _refreshDataIfNeeded() async {
    // 이미 로딩 중이면 중복 실행 방지
    if (_isLoading) return;

    print('🔄 데이터 새로고침 확인...');
    await _loadMealData();
  }

  void _loadDeveloperModeStatus() async {
    final isEnabled = await DeveloperMode.isEnabled();
    setState(() {
      _isDeveloperModeEnabled = isEnabled;
    });
  }

  Future<void> _initializeData() async {
    _controller.loadAvailableDates();

    if (_controller.availableDates.isNotEmpty) {
      _pageController =
          PageController(initialPage: _controller.currentDateIndex);
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
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_controller.availableDates.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            '사용 가능한 날짜가 없습니다.',
            style: TextStyle(fontSize: 16, color: AppColors.secondaryDark),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
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
    // 화면 크기 감지
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // 태블릿에서 패딩과 폰트 크기 조정
    final padding = isTablet ? 24.0 : 16.0;
    final titleFontSize = isTablet ? 24.0 : 20.0;
    final spacing = isTablet ? 24.0 : 20.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: spacing),

          // 개발자 모드 상태 표시
          if (_isDeveloperModeEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.developer_mode, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    '개발자 모드: 날짜 제한 해제됨',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // 오늘의 급식 정보
          Text(
            '${_controller.getCurrentDateString()} 급식 메뉴',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.secondaryDark,
            ),
          ),

          const SizedBox(height: 12),

          if (_controller.todayMeal != null &&
              _controller.todayMeal!.menuList.isNotEmpty) ...[
            // 메뉴 리스트
            MenuListCard(meal: _controller.todayMeal!),

            const SizedBox(height: 20),

            // 획득 가능한 재료 섹션
            IngredientsSection(availableFoods: _controller.availableFoods),

            const SizedBox(height: 20),

            // 재료 획득 카드
            IngredientAcquisitionCard(
              meal: _controller.todayMeal!,
              availableFoods: _controller.availableFoods,
              onAcquirePressed: () async {
                await _controller.acquireIngredients();
                // UI 갱신을 위해 데이터 다시 로드
                await _loadMealData();
              },
            ),
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
                  color: AppColors.secondaryDark,
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
