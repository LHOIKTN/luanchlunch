import 'package:flutter/material.dart';
import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/data/food_data.dart';
import 'package:launchlunch/features/inventory/food_detail_modal.dart';
import 'package:launchlunch/features/inventory/complete_overlay.dart';
import 'package:launchlunch/features/inventory/food_grid_item.dart';
import 'package:launchlunch/features/inventory/combination_box.dart';
import 'package:launchlunch/theme/app_colors.dart';
import 'package:launchlunch/utils/date_helper.dart';
import 'package:launchlunch/utils/developer_mode.dart';
import 'package:launchlunch/data/hive/hive_helper.dart';

class FoodGridScreen extends StatefulWidget {
  const FoodGridScreen({super.key});

  @override
  State<FoodGridScreen> createState() => _FoodGridScreenState();
}

class _FoodGridScreenState extends State<FoodGridScreen> {
  List<Food> selectedFoods = [];
  List<Food> availableFoods = []; // 로컬 상태로 관리
  Food? resultFood;
  bool isCombinationFailed = false; // 조합 실패 상태
  Food? selectedFoodForDetail; // 상세 정보를 보여줄 재료
  bool isLoading = true; // 로딩 상태
  bool _isDeveloperModeEnabled = false; // 개발자 모드 상태

  final FoodDataManager _foodDataManager = FoodDataManager();

  @override
  void initState() {
    super.initState();
    _loadFoodsFromHive();
    _loadDeveloperModeStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 활성화될 때마다 데이터 새로고침
    _loadFoodsFromHive();
    _loadDeveloperModeStatus();
  }

  void _loadDeveloperModeStatus() async {
    final isEnabled = await DeveloperMode.isEnabled();
    setState(() {
      _isDeveloperModeEnabled = isEnabled;
    });
  }

  /// 날짜 제한 확인
  bool _isDateRestrictionEnabled() {
    // 개발자 모드가 활성화되어 있으면 날짜 제한 해제
    if (_isDeveloperModeEnabled) {
      return false;
    }
    return true; // 개발자 모드가 비활성화되어 있으면 날짜 제한 적용
  }

  /// 해당 날짜의 음식인지 확인
  bool _isTodayFood(Food food) {
    if (!_isDateRestrictionEnabled()) {
      return true; // 개발자 모드면 모든 음식 허용
    }

    // 급식 데이터에서 해당 음식이 오늘 날짜에 포함되는지 확인
    final meals = HiveHelper.instance.getAllMeals();
    final currentDate = DateHelper.getCurrentOrTestDate();

    for (final meal in meals) {
      if (DateHelper.isTodayMeal(meal.lunchDate) &&
          meal.foods.contains(food.id)) {
        return true;
      }
    }

    return false; // 오늘 날짜에 해당하지 않음
  }

  /// Hive에서 획득한 음식 데이터를 로드하고 날짜순으로 정렬합니다.
  Future<void> _loadFoodsFromHive() async {
    try {
      setState(() {
        isLoading = true;
      });

      await _foodDataManager.loadFoodsFromHive();

      // 획득한 음식들만 가져와서 획득일자 빠른 순으로 정렬
      final obtainedFoods = _foodDataManager.allFoods
          .where((food) => food.acquiredAt != null)
          .toList();

      // 획득일자 빠른 순으로 정렬
      obtainedFoods.sort((a, b) => a.acquiredAt!.compareTo(b.acquiredAt!));

      setState(() {
        availableFoods = obtainedFoods;
        isLoading = false;
      });

      print('✅ 획득한 음식 ${availableFoods.length}개 로드 완료 (날짜순 정렬)');
    } catch (e) {
      print('❌ Hive 데이터 로드 실패: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addToCombinationBox(Food food) {
    if (selectedFoods.length >= 3) return;

    setState(() {
      selectedFoods.add(food);
      resultFood = null; // 재료가 바뀌면 항상 결과 초기화
      isCombinationFailed = false;
    });
  }

  void _removeFromCombinationBox(Food food) {
    setState(() {
      selectedFoods.remove(food);
      resultFood = null; // 재료가 바뀌면 항상 결과 초기화
      isCombinationFailed = false;
    });
  }

  void _clearCombinationBox() {
    setState(() {
      selectedFoods.clear();
      resultFood = null; // 재료가 바뀌면 항상 결과 초기화
      isCombinationFailed = false;
    });
  }

  void _onCompleteRecipe(Food recipe) async {
    // 조합 실패 처리 (id가 -1인 경우)
    if (recipe.id == -1) {
      setState(() {
        resultFood = null;
        isCombinationFailed = true;
      });
      return;
    }

    setState(() {
      resultFood = recipe;
      isCombinationFailed = false;
    });

    // 레시피 완성 처리 (Hive와 Supabase에 저장)
    await _foodDataManager.addCompletedRecipe(recipe);

    // 획득일자 설정 후 로컬 상태에 바로 추가
    final newFood = recipe.copyWith(acquiredAt: DateTime.now());

    setState(() {
      // 새로 획득한 음식을 availableFoods에 추가
      availableFoods.add(newFood);
      // 획득일자 빠른 순으로 다시 정렬
      availableFoods.sort((a, b) => a.acquiredAt!.compareTo(b.acquiredAt!));
    });

    print('✅ 새로 획득한 음식 ${recipe.name}을 조합 화면에 바로 추가');
  }

  void _showFoodDetail(Food food) {
    setState(() {
      selectedFoodForDetail = food;
    });
  }

  void _hideFoodDetail() {
    setState(() {
      selectedFoodForDetail = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 화면 크기 및 방향 감지
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isTablet = screenSize.shortestSide >= 600;
    final isLandscape = screenWidth > screenHeight;

    // 디바이스 타입과 방향에 따른 그리드 설정 조정
    int crossAxisCount;
    if (isTablet) {
      crossAxisCount = isLandscape ? 8 : 6; // 태블릿: 가로 8개, 세로 6개
    } else {
      crossAxisCount = 4; // 모바일: 항상 4개
    }

    final childAspectRatio = isTablet ? 0.8 : 0.6;
    final horizontalPadding = isTablet ? 24.0 : 16.0;
    final verticalPadding = isTablet ? 24.0 : 16.0;
    final fontSize = isTablet ? 20.0 : 18.0;
    final spacing = isTablet ? 12.0 : 8.0;
    final crossSpacing = isTablet ? 16.0 : 12.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: isTablet ? 24.0 : 20.0),

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

                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : availableFoods.isEmpty // 로컬 상태 사용
                            ? Center(
                                child: Text(
                                  '사용 가능한 재료가 없습니다.',
                                  style: TextStyle(
                                      fontSize: fontSize, color: Colors.grey),
                                ),
                              )
                            : GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: spacing,
                                  crossAxisSpacing: crossSpacing,
                                  childAspectRatio: childAspectRatio,
                                ),
                                itemCount: availableFoods.length, // 로컬 상태 사용
                                itemBuilder: (context, index) {
                                  final food =
                                      availableFoods[index]; // 로컬 상태 사용
                                  return FoodGridItem(
                                    food: food,
                                    onTap: () => _addToCombinationBox(food),
                                    onLongPress: () => _showFoodDetail(food),
                                  );
                                },
                              ),
                  ),
                  CombinationBox(
                    selectedFoods: selectedFoods,
                    allFoods: _foodDataManager.allFoods,
                    availableFoods: availableFoods,
                    resultFood: resultFood,
                    isCombinationFailed: isCombinationFailed,
                    onRemoveFood: _removeFromCombinationBox,
                    onClearCombination: _clearCombinationBox,
                    onCompleteRecipe: (recipe) async {
                      _onCompleteRecipe(recipe);

                      // 조합 실패가 아닌 경우에만 완성 오버레이 띄우기
                      if (recipe.id != -1) {
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => CompleteOverlay(
                            food: recipe,
                            allFoods: _foodDataManager.allFoods, // 모든 음식 목록 전달
                            onClose: () {
                              Navigator.of(context).pop();
                              _clearCombinationBox();
                            },
                            onLongPress: () {},
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (selectedFoodForDetail != null)
            Positioned.fill(
              child: FoodDetailModal(
                food: selectedFoodForDetail!,
                allFoods: _foodDataManager.allFoods, // 모든 음식 목록 전달
                onIngredientTap: (f) =>
                    setState(() => selectedFoodForDetail = f),
                onClose: _hideFoodDetail,
              ),
            ),
        ],
      ),
    );
  }
}
