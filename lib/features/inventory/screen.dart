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

  /// Hive에서 음식 데이터를 로드합니다.
  Future<void> _loadFoodsFromHive() async {
    try {
      setState(() {
        isLoading = true;
      });

      await _foodDataManager.loadFoodsFromHive();

      setState(() {
        isLoading = false;
      });
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

    // 레시피 완성 처리
    await _foodDataManager.addCompletedRecipe(recipe);

    // UI 업데이트 - 새로 추가된 음식만 리스트에 추가
    setState(() {
      // availableFoods에 새로 추가된 음식이 이미 포함되어 있음
      // FoodDataManager.addCompletedRecipe에서 이미 업데이트됨
    });
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
    final stats = _foodDataManager.getProgressStats();
    final totalCount = stats['total']!;
    final ownedCount = stats['owned']! + selectedFoods.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      '$ownedCount/$totalCount',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: _foodDataManager.availableFoods.isEmpty
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
                                  itemCount:
                                      _foodDataManager.availableFoods.length,
                                  itemBuilder: (context, index) {
                                    final food =
                                        _foodDataManager.availableFoods[index];
                                    return FoodGridItem(
                                      food: food,
                                      onTap: () => _addToCombinationBox(food),
                                      onLongPress: () => _showFoodDetail(food),
                                    );
                                  },
                                ),
                        ),
                ),
                CombinationBox(
                  selectedFoods: selectedFoods,
                  allFoods: _foodDataManager.allFoods,
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
