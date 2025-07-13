import 'package:launchlunch/models/foods.dart';
import 'package:flutter/material.dart';

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

  void _addToCombinationBox(Food food) {
    if (selectedFoods.length >= 3) return;
    setState(() {
      availableFoods.removeWhere((element) => element.id == food.id);
      selectedFoods.add(food);
      resultFood = null;
    });
  }

  void _removeFromCombinationBox(Food food) {
    setState(() {
      selectedFoods.removeWhere((element) => element.id == food.id);
      availableFoods.add(food);
      resultFood = null;
    });
  }

  void _clearCombinationBox() {
    setState(() {
      availableFoods.addAll(selectedFoods);
      selectedFoods.clear();
      resultFood = null;
    });
  }

  void _combineIngredients() {
    if (selectedFoods.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('조합하려면 2개 이상의 재료가 필요합니다.')),
      );
      return;
    }
    // 예시: 쌀+블루베리=블루베리밥
    final hasRice = selectedFoods.any((food) => food.name == "쌀");
    final hasBlueberry = selectedFoods.any((food) => food.name == "블루베리");
    if (hasRice && hasBlueberry) {
      final blueberryRice = sampleFoods.firstWhere((food) => food.name == "블루베리밥");
      setState(() {
        resultFood = blueberryRice;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('블루베리밥을 만들었습니다!'), backgroundColor: Colors.green),
      );
    } else {
      setState(() {
        resultFood = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 재료들로는 조합할 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = sampleFoods.length;
    final ownedCount = totalCount - availableFoods.length + selectedFoods.length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        toolbarHeight: 0, // 상단 AppBar 숨김
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 중앙 보유/전체 텍스트
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  '$ownedCount/$totalCount',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // 재료 그리드
            Expanded(
              child: availableFoods.isEmpty
                  ? const Center(
                      child: Text(
                        '사용 가능한 재료가 없습니다.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: availableFoods.length,
                        itemBuilder: (context, index) {
                          final food = availableFoods[index];
                          return GestureDetector(
                            onTap: () => _addToCombinationBox(food),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Image.asset(
                                      food.imagePath,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  food.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '터치하여 조합',
                                  style: TextStyle(fontSize: 11, color: Colors.blue),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
            // 하단 조합 슬롯 3개 + 결과 + 초기화
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 조합 슬롯 3개
                  ...List.generate(3, (i) {
                    if (i < selectedFoods.length) {
                      final food = selectedFoods[i];
                      return GestureDetector(
                        onTap: () => _removeFromCombinationBox(food),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(8),
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(food.imagePath, height: 40),
                              const SizedBox(height: 4),
                              Text(
                                food.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              const Text(
                                '제거',
                                style: TextStyle(fontSize: 9, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(Icons.add, color: Colors.grey, size: 32),
                      );
                    }
                  }),
                  // > 아이콘
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, size: 32, color: Colors.grey),
                  ),
                  // 결과 아이콘
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: resultFood != null
                        ? Image.asset(resultFood!.imagePath, height: 32)
                        : const Icon(Icons.science, color: Colors.blueGrey, size: 32),
                  ),
                  // 조합 버튼
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ElevatedButton(
                      onPressed: selectedFoods.length >= 2 ? _combineIngredients : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                        shape: const CircleBorder(),
                        elevation: 0,
                      ),
                      child: const Icon(Icons.check, size: 28),
                    ),
                  ),
                  // 초기화 버튼
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: selectedFoods.isNotEmpty ? _clearCombinationBox : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FoodDetailScreen extends StatelessWidget {
  final Food food;
  const FoodDetailScreen({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(food.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(food.imagePath, width: 200, height: 200),
            const SizedBox(height: 20),
            Text(food.name, style: const TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
