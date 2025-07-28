import 'package:flutter/material.dart';
import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/data/food_data.dart';
import 'package:launchlunch/features/inventory/food_detail_modal.dart';
import 'package:launchlunch/features/inventory/complete_overlay.dart';
import 'package:launchlunch/features/inventory/food_grid_item.dart';
import 'package:launchlunch/features/inventory/combination_box.dart';

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

  final FoodDataManager _foodDataManager = FoodDataManager();

  @override
  void initState() {
    super.initState();
    _loadFoodsFromHive();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 활성화될 때마다 데이터 새로고침
    _loadFoodsFromHive();
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : availableFoods.isEmpty // 로컬 상태 사용
                                ? const Center(
                                    child: Text(
                                      '사용 가능한 재료가 없습니다.',
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.grey),
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 0.6,
                                    ),
                                    itemCount: availableFoods.length, // 로컬 상태 사용
                                    itemBuilder: (context, index) {
                                      final food = availableFoods[index]; // 로컬 상태 사용
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
