import 'package:flutter/material.dart';
import '../../data/models/ingredient.dart';
import '../../data/models/inventory.dart';

// 샘플 재료 데이터 (계란, 밥, 김밥만)
final sampleIngredients = [
  Ingredient(id: 'egg', name: '계란', imageUrl: 'assets/egg.jpg'),
  Ingredient(id: 'rice', name: '밥', imageUrl: 'assets/rice.jpg'),
  Ingredient(id: 'kimbap', name: '김밥', imageUrl: 'assets/kimbap.jpg'),
];

// 샘플 인벤토리 데이터 (계란, 밥만)
final sampleInventory = [
  InventoryItem(id: '1', ingredientId: 'egg', acquiredAt: DateTime.now()),
  InventoryItem(id: '2', ingredientId: 'rice', acquiredAt: DateTime.now()),
];

class InventoryScreen extends StatelessWidget {
  final List<InventoryItem>? inventory;
  final List<Ingredient>? ingredients;

  const InventoryScreen({
    super.key,
    this.inventory,
    this.ingredients,
  });

  @override
  Widget build(BuildContext context) {
    final inv = inventory ?? sampleInventory;
    final ing = ingredients ?? sampleIngredients;
    return Scaffold(
      appBar: AppBar(title: const Text('내 재료 보관함')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: inv.length,
        itemBuilder: (context, index) {
          final item = inv[index];
          final ingredient = ing.firstWhere((i) => i.id == item.ingredientId);
          return Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(ingredient.imageUrl, height: 48),
                const SizedBox(height: 8),
                Text(ingredient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('획득: ${item.acquiredAt.month}/${item.acquiredAt.day}'),
              ],
            ),
          );
        },
      ),
    );
  }
} 