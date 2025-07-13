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

class InventoryScreen extends StatefulWidget {
  final List<InventoryItem>? inventory;
  final List<Ingredient>? ingredients;

  const InventoryScreen({
    super.key,
    this.inventory,
    this.ingredients,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late List<InventoryItem> inventory;
  late List<Ingredient> ingredients;
  List<InventoryItem> combinationBox = []; // 조합 박스에 들어간 재료들

  @override
  void initState() {
    super.initState();
    inventory = widget.inventory ?? sampleInventory;
    ingredients = widget.ingredients ?? sampleIngredients;
  }

  void _addToCombinationBox(InventoryItem item) {
    setState(() {
      // 인벤토리에서 제거
      inventory.removeWhere((element) => element.id == item.id);
      // 조합 박스에 추가
      combinationBox.add(item);
    });
  }

  void _removeFromCombinationBox(InventoryItem item) {
    setState(() {
      // 조합 박스에서 제거
      combinationBox.removeWhere((element) => element.id == item.id);
      // 인벤토리에 다시 추가
      inventory.add(item);
    });
  }

  void _clearCombinationBox() {
    setState(() {
      // 조합 박스의 모든 재료를 인벤토리로 되돌리기
      inventory.addAll(combinationBox);
      combinationBox.clear();
    });
  }

  void _combineIngredients() {
    if (combinationBox.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('조합하려면 2개 이상의 재료가 필요합니다.')),
      );
      return;
    }

    // 간단한 조합 로직 (계란 + 밥 = 김밥)
    final hasEgg = combinationBox.any((item) => item.ingredientId == 'egg');
    final hasRice = combinationBox.any((item) => item.ingredientId == 'rice');

    if (hasEgg && hasRice) {
      // 김밥 생성
      final kimbapItem = InventoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        ingredientId: 'kimbap',
        acquiredAt: DateTime.now(),
      );
      
      setState(() {
        combinationBox.clear(); // 조합 박스 비우기
        inventory.add(kimbapItem); // 김밥을 인벤토리에 추가
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('김밥을 만들었습니다!'),
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
        title: const Text('내 재료 보관함'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 상단: 스크롤 가능한 재료 목록
          Expanded(
            child: inventory.isEmpty
                ? const Center(
                    child: Text(
                      '획득한 재료가 없습니다.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: inventory.length,
                    itemBuilder: (context, index) {
                      final item = inventory[index];
                      final ingredient = ingredients.firstWhere((i) => i.id == item.ingredientId);
                      return GestureDetector(
                        onTap: () => _addToCombinationBox(item),
                        child: Card(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(ingredient.imageUrl, height: 48),
                              const SizedBox(height: 8),
                              Text(
                                ingredient.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '획득: ${item.acquiredAt.month}/${item.acquiredAt.day}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '터치하여 조합',
                                style: TextStyle(fontSize: 10, color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
                    if (combinationBox.isNotEmpty)
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
                  child: combinationBox.isEmpty
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
                                itemCount: combinationBox.length,
                                itemBuilder: (context, index) {
                                  final item = combinationBox[index];
                                  final ingredient = ingredients.firstWhere((i) => i.id == item.ingredientId);
                                  return GestureDetector(
                                    onTap: () => _removeFromCombinationBox(item),
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
                                          Image.asset(ingredient.imageUrl, height: 32),
                                          const SizedBox(height: 4),
                                          Text(
                                            ingredient.name,
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
                            if (combinationBox.length >= 2)
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