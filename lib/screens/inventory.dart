import 'package:flutter/material.dart';
import 'package:launchlunch/models/foods.dart';
import 'dart:math' as math;
import 'package:collection/collection.dart';

// --- 커스텀 위젯/클래스 최상단 선언 ---
class FoodDetailModal extends StatelessWidget {
  final Food food;
  final void Function(Food) onIngredientTap;
  final VoidCallback onClose;
  const FoodDetailModal({
    required this.food,
    required this.onIngredientTap,
    required this.onClose,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recipeFoods = food.recipeIds?.map((id) => sampleFoods.firstWhere((f) => f.id == id)).toList() ?? [];
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(food.imagePath, width: 80, height: 80, fit: BoxFit.contain),
                  const SizedBox(height: 16),
                  Text(food.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text('${food.name}에 대한 설명입니다. 다양한 요리에 활용할 수 있는 재료입니다.', style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
                  if (recipeFoods.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('레시피', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: recipeFoods.map((f) => GestureDetector(
                        onTap: () => onIngredientTap(f),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              Image.asset(f.imagePath, width: 40, height: 40),
                              const SizedBox(height: 4),
                              Text(f.name, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton(onPressed: onClose, child: const Text('닫기')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CompleteOverlay extends StatelessWidget {
  final Food food;
  final VoidCallback onClose;
  final VoidCallback onLongPress;
  const CompleteOverlay({
    required this.food,
    required this.onClose,
    required this.onLongPress,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      onLongPress: onLongPress,
      child: Container(
        color: Colors.white.withOpacity(0.95),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RaysPainter(color: Colors.blue.shade100),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(food.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 40),
                  Image.asset(food.imagePath, width: 120, height: 120),
                  const SizedBox(height: 40),
                  const Text('탭하여 계속', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  final Color color;
  _RaysPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 3.14159 * 2;
      final x = size.width / 2 + size.width * 1.2 * math.cos(angle);
      final y = size.height / 2 + size.height * 1.2 * math.sin(angle);
      canvas.drawLine(Offset(size.width / 2, size.height / 2), Offset(x, y), paint..strokeWidth = 24);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- 이하 기존 Food, sampleFoods, FoodGridScreen 등 ---

// 1. Food 모델에 레시피 정보 추가(샘플)
class Food {
  final int id;
  final String name;
  final String imagePath;
  final List<int>? recipeIds; // 조합에 사용된 재료 id 목록(없으면 원재료)

  Food({required this.id, required this.name, required this.imagePath, this.recipeIds});
}

// 2. sampleFoods에 레시피 정보 추가(예시)
final List<Food> sampleFoods = [
  Food(id: 1, name: "쌀", imagePath: "assets/images/rice.webp"),
  Food(id: 2, name: "소금", imagePath: "assets/images/salt.webp"),
  Food(id: 3, name: "설탕", imagePath: "assets/images/sugar.webp"),
  Food(id: 4, name: "마늘", imagePath: "assets/images/garlic.webp"),
  Food(id: 5, name: "대파", imagePath: "assets/images/green_onion.webp"),
  Food(id: 6, name: "참기름", imagePath: "assets/images/sesame_oil.webp"),
  Food(id: 7, name: "고추", imagePath: "assets/images/gochu.webp"),
  Food(id: 8, name: "고춧가루", imagePath: "assets/images/gochugaru.webp"),
  Food(id: 9, name: "콩나물", imagePath: "assets/images/bean_sprout.webp"),
  Food(id: 11, name: "블루베리", imagePath: "assets/images/blueberry.webp"),
  Food(id: 12, name: "닭고기", imagePath: "assets/images/chicken.webp"),
  Food(id: 10, name: "알타리무", imagePath: "assets/images/ponytail_radish.webp"),
  Food(id: 13, name: "양상추", imagePath: "assets/images/lettuce.webp"),
  Food(id: 14, name: "배추", imagePath: "assets/images/napa_cabbage.webp"),
  Food(id: 15, name: "미역", imagePath: "assets/images/seaweed.webp"),
  Food(id: 16, name: "블루베리밥", imagePath: "assets/images/blueberry_rice.webp", recipeIds: [1, 11]),
  Food(id: 17, name: "감자", imagePath: "assets/images/potato.webp"),
];

class FoodGridScreen extends StatefulWidget {
  const FoodGridScreen({super.key});

  @override
  State<FoodGridScreen> createState() => _FoodGridScreenState();
}

class _FoodGridScreenState extends State<FoodGridScreen> {
  List<Food> selectedFoods = [];
  // 완성품(레시피가 있는 Food)은 인벤토리에서 숨김
  List<Food> availableFoods = sampleFoods.where((f) => f.recipeIds == null).toList();
  Food? resultFood;
  bool isCombinationFailed = false; // 조합 실패 상태
  Food? selectedFoodForDetail; // 상세 정보를 보여줄 재료
  Set<int> ownedRecipeIds = {}; // 획득한 레시피 id 목록

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

  void _combineIngredients() {
    if (selectedFoods.length < 2) {
      isCombinationFailed = true;
      setState(() {});
      return;
    }
    // 샘플: 쌀+블루베리=블루베리밥
    final hasRice = selectedFoods.any((food) => food.name == "쌀");
    final hasBlueberry = selectedFoods.any((food) => food.name == "블루베리");
    if (hasRice && hasBlueberry) {
      final blueberryRice = sampleFoods.firstWhere((food) => food.name == "블루베리밥");
      setState(() {
        resultFood = blueberryRice;
        ownedRecipeIds.add(blueberryRice.id);
        isCombinationFailed = false;
      });
    } else {
      setState(() {
        resultFood = null;
        isCombinationFailed = true;
      });
    }
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
    final totalCount = sampleFoods.length;
    final ownedCount = totalCount - availableFoods.length + selectedFoods.length;

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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: availableFoods.isEmpty
                    ? const Center(
                        child: Text(
                          '사용 가능한 재료가 없습니다.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
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
                        itemCount: availableFoods.length,
                        itemBuilder: (context, index) {
                          final food = availableFoods[index];
                          return GestureDetector(
                            onTap: () => _addToCombinationBox(food),
                            onLongPress: () => _showFoodDetail(food),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Image.asset(
                                      food.imagePath,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  food.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              color: Colors.grey.shade100,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(3, (i) {
                      if (i < selectedFoods.length) {
                        final food = selectedFoods[i];
                        return GestureDetector(
                          onTap: () => _removeFromCombinationBox(food),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(6),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(food.imagePath, height: 32),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Image.asset(
                            'assets/images/cooking.png',
                            width: 32,
                            height: 32,
                            color: Colors.white,
                          ),
                        );
                      }
                    }),
                    const SizedBox(width: 12),
                    // 조합/완성품/X 영역
                    Builder(
                      builder: (context) {
                        final canCombine = selectedFoods.length >= 2;
                        Food? matchedRecipe;
                        if (canCombine) {
                          // 조합된 재료 id 리스트
                          final selectedIds = selectedFoods.map((f) => f.id).toList()..sort();
                          for (final food in sampleFoods) {
                            if (food.recipeIds != null) {
                              final recipeIds = List<int>.from(food.recipeIds!)..sort();
                              if (recipeIds.length == selectedIds.length &&
                                  const ListEquality().equals(recipeIds, selectedIds)) {
                                matchedRecipe = food;
                                break;
                              }
                            }
                          }
                        }
                        // 조합 버튼을 눌렀을 때의 결과 상태
                        bool showResult = resultFood != null || isCombinationFailed;
                        if (showResult) {
                          if (resultFood != null && matchedRecipe != null) {
                            // 완성품 노출
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Image.asset(
                                matchedRecipe.imagePath,
                                height: 48,
                              ),
                            );
                          } else {
                            // X 표시
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 40,
                              ),
                            );
                          }
                        } else if (canCombine) {
                          // cooking.png 활성화(컬러, 하늘색 배경, 작게)
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (matchedRecipe != null) {
                                  resultFood = matchedRecipe;
                                  ownedRecipeIds.add(matchedRecipe.id);
                                  isCombinationFailed = false;
                                  // 완성품이 인벤토리에 없으면 추가
                                  if (!availableFoods.any((f) => f.id == matchedRecipe!.id)) {
                                    availableFoods.add(matchedRecipe!);
                                  }
                                } else {
                                  resultFood = null;
                                  isCombinationFailed = true;
                                }
                              });
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.lightBlue[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset(
                                'assets/images/cooking.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          );
                        } else {
                          // 비활성화(흑백, 투명 배경, 작게)
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ColorFiltered(
                              colorFilter: const ColorFilter.matrix(<double>[
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0.2126, 0.7152, 0.0722, 0, 0,
                                0, 0, 0, 1, 0,
                              ]),
                              child: Image.asset(
                                'assets/images/cooking.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
          if (selectedFoodForDetail != null)
            Positioned.fill(
              child: FoodDetailModal(
                food: selectedFoodForDetail!,
                onIngredientTap: (f) => setState(() => selectedFoodForDetail = f),
                onClose: _hideFoodDetail,
              ),
            ),
        ],
      ),
    );
  }
}
