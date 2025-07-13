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
// 📦 식재료 그리드 화면
// ──────────────────────
class FoodGridScreen extends StatelessWidget {
  const FoodGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8, // 카드+텍스트 비율 조절
          children: sampleFoods.map((food) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodDetailScreen(food: food),
                  ),
                );
              },
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
                ],
              ),
            );
          }).toList(),
        ),
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
