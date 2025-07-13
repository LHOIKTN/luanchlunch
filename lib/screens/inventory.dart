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

// ──────────────────────
// 📦 식재료 그리드 화면 (조합 기능 포함)
// ──────────────────────
class FoodGridScreen extends StatefulWidget {
  const FoodGridScreen({super.key});

  @override
  State<FoodGridScreen> createState() => _FoodGridScreenState();
}

class _FoodGridScreenState extends State<FoodGridScreen> {
  List<Food> selectedFoods = []; // 조합 박스에 선택된 재료들
  List<Food> availableFoods = List.from(sampleFoods); // 사용 가능한 재료들

  void _addToCombinationBox(Food food) {
    setState(() {
      // 사용 가능한 재료에서 제거
      availableFoods.removeWhere((element) => element.id == food.id);
      // 조합 박스에 추가
      selectedFoods.add(food);
    });
  }

  void _removeFromCombinationBox(Food food) {
    setState(() {
      // 조합 박스에서 제거
      selectedFoods.removeWhere((element) => element.id == food.id);
      // 사용 가능한 재료에 다시 추가
      availableFoods.add(food);
    });
  }

  void _clearCombinationBox() {
    setState(() {
      // 조합 박스의 모든 재료를 사용 가능한 재료로 되돌리기
      availableFoods.addAll(selectedFoods);
      selectedFoods.clear();
    });
  }

  void _combineIngredients() {
    if (selectedFoods.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('조합하려면 2개 이상의 재료가 필요합니다.')),
      );
      return;
    }

    // 간단한 조합 로직 예시
    final hasRice = selectedFoods.any((food) => food.name == "쌀");
    final hasBlueberry = selectedFoods.any((food) => food.name == "블루베리");

    if (hasRice && hasBlueberry) {
      // 블루베리밥 생성
      final blueberryRice = sampleFoods.firstWhere((food) => food.name == "블루베리밥");
      
      setState(() {
        selectedFoods.clear(); // 조합 박스 비우기
        availableFoods.add(blueberryRice); // 블루베리밥을 사용 가능한 재료에 추가
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('블루베리밥을 만들었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 재료들로는 조합할 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 상단: 스크롤 가능한 재료 목록
          Expanded(
            child: availableFoods.isEmpty
                ? const Center(
                    child: Text(
                      '사용 가능한 재료가 없습니다.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(12),
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
                                  padding: const EdgeInsets.all(12),
                                  child: Image.asset(
                                    food.imagePath,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                food.name,
                                style: const TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '터치하여 조합',
                                style: TextStyle(fontSize: 10, color: Colors.blue),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
          // 하단: 고정된 조합 박스
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.restaurant, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      '재료 조합',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (selectedFoods.isNotEmpty)
                      TextButton(
                        onPressed: _clearCombinationBox,
                        child: const Text('초기화'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // 조합 박스 내용
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: selectedFoods.isEmpty
                      ? const Center(
                          child: Text(
                            '재료를 터치하여 조합 박스에 추가하세요',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(8),
                                itemCount: selectedFoods.length,
                                itemBuilder: (context, index) {
                                  final food = selectedFoods[index];
                                  return GestureDetector(
                                    onTap: () => _removeFromCombinationBox(food),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Image.asset(food.imagePath, height: 32),
                                          const SizedBox(height: 4),
                                          Text(
                                            food.name,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          const Text(
                                            '터치하여 제거',
                                            style: TextStyle(fontSize: 8, color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (selectedFoods.length >= 2)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                  onPressed: _combineIngredients,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('조합'),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────
// 🔍 상세 화면
// ──────────────────────
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
