import 'package:flutter/material.dart';
import 'package:launchlunch/models/foods.dart';

final List<Food> sampleFoods = [
  Food(id: 9, name: "콩나물", imagePath: "assets/images/bean_sprout.webp"),
  Food(id: 16, name: "블루베리밥", imagePath: "assets/images/blueberry_rice.webp"),
  Food(id: 11, name: "블루베리", imagePath: "assets/images/blueberry.webp"),
  Food(id: 12, name: "닭고기", imagePath: "assets/images/chicken.webp"),
  Food(id: 4, name: "마늘", imagePath: "assets/images/garlic.webp"),
  Food(id: 7, name: "고추", imagePath: "assets/images/gochu.webp"),
  Food(id: 8, name: "고춧가루", imagePath: "assets/images/gochugaru.webp"),
  Food(id: 5, name: "대파", imagePath: "assets/images/green_onion.webp"),
  Food(id: 13, name: "양상추", imagePath: "assets/images/lettuce.webp"),
  Food(id: 14, name: "배추", imagePath: "assets/images/napa_cabbage.webp"),
  Food(id: 10, name: "알타리무", imagePath: "assets/images/ponytail_radish.webp"),
  Food(id: 17, name: "감자", imagePath: "assets/images/potato.webp"),
  Food(id: 1, name: "쌀", imagePath: "assets/images/rice.webp"),
  Food(id: 2, name: "소금", imagePath: "assets/images/salt.webp"),
  Food(id: 15, name: "미역", imagePath: "assets/images/seaweed.webp"),
  Food(id: 6, name: "참기름", imagePath: "assets/images/sesame_oil.webp"),
  Food(id: 3, name: "설탕", imagePath: "assets/images/sugar.webp"),
];

class FoodGridScreen extends StatefulWidget {
  const FoodGridScreen({super.key});

  @override
  State<FoodGridScreen> createState() => _FoodGridScreenState();
}

class _FoodGridScreenState extends State<FoodGridScreen> {
  List<Food> selectedFoods = [];
  List<Food> availableFoods = List.from(sampleFoods);
  Food? resultFood;
  bool isCombinationFailed = false; // 조합 실패 상태
  Food? selectedFoodForDetail; // 상세 정보를 보여줄 재료
  Set<int> ownedRecipeIds = {}; // 획득한 레시피 id 목록

  void _addToCombinationBox(Food food) {
    if (selectedFoods.length >= 3) return;
    setState(() {
      availableFoods.removeWhere((element) => element.id == food.id);
      selectedFoods.add(food);
      resultFood = null;
      isCombinationFailed = false; // 새로운 재료 추가 시 실패 상태 초기화
    });
  }

  void _removeFromCombinationBox(Food food) {
    setState(() {
      selectedFoods.removeWhere((element) => element.id == food.id);
      availableFoods.add(food);
      resultFood = null;
      isCombinationFailed = false; // 재료 제거 시 실패 상태 초기화
    });
  }

  void _clearCombinationBox() {
    setState(() {
      availableFoods.addAll(selectedFoods);
      selectedFoods.clear();
      resultFood = null;
      isCombinationFailed = false; // 조합 박스 초기화 시 실패 상태 초기화
    });
  }

  void _combineIngredients() {
    if (selectedFoods.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('조합하려면 2개 이상의 재료가 필요합니다.'))
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('블루베리밥을 만들었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        resultFood = null;
        isCombinationFailed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이 재료들로는 조합할 수 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
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
    final ownedCount =
        totalCount - availableFoods.length + selectedFoods.length;

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
                          child: const Icon(
                            Icons.add,
                            color: Colors.grey,
                            size: 28,
                          ),
                        );
                      }
                    }),
                    const SizedBox(width: 12),
                    // 조합/완성품 영역
                    Builder(
                      builder: (context) {
                        // 샘플: 쌀+블루베리=블루베리밥
                        final hasRice = selectedFoods.any((food) => food.name == "쌀");
                        final hasBlueberry = selectedFoods.any((food) => food.name == "블루베리");
                        final canCombine = selectedFoods.length >= 2 && hasRice && hasBlueberry;
                        final resultId = 16; // 블루베리밥 id
                        final alreadyOwned = ownedRecipeIds.contains(resultId);
                        if (alreadyOwned) {
                          // 완성품 노출, 조합 불가
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Image.asset(
                              sampleFoods.firstWhere((f) => f.id == resultId).imagePath,
                              height: 48,
                            ),
                          );
                        } else {
                          // 플라스크 노출
                          return GestureDetector(
                            onTap: canCombine ? _combineIngredients : null,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: canCombine ? Colors.blue : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.science,
                                color: Colors.white,
                                size: 28,
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
          // Food Detail Modal
          if (selectedFoodForDetail != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: _hideFoodDetail,
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {}, // 모달 내부 터치 시 닫히지 않도록
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              selectedFoodForDetail!.imagePath,
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              selectedFoodForDetail!.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${selectedFoodForDetail!.name}에 대한 설명입니다.\n다양한 요리에 활용할 수 있는 재료입니다.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _hideFoodDetail,
                              child: const Text('닫기'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
