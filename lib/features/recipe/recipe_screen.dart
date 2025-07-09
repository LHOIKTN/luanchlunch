import 'package:flutter/material.dart';
import '../../data/models/recipe.dart';
import '../../data/models/ingredient.dart';
import '../../data/models/inventory.dart';
import '../../widgets/combine_animation.dart';

// 샘플 재료/인벤토리/레시피 데이터 (계란, 밥, 김밥)
final sampleIngredients = [
  Ingredient(id: 'egg', name: '계란', imageUrl: 'assets/egg.jpg'),
  Ingredient(id: 'rice', name: '밥', imageUrl: 'assets/rice.jpg'),
  Ingredient(id: 'kimbap', name: '김밥', imageUrl: 'assets/kimbap.jpg'),
];

final sampleRecipe = Recipe(
  id: 'kimbap',
  name: '김밥',
  imageUrl: 'assets/kimbap.jpg',
  ingredientIds: ['egg', 'rice'],
);

class RecipeScreen extends StatefulWidget {
  const RecipeScreen({super.key});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  // 임시 인벤토리 상태 (계란, 밥만 보유)
  List<InventoryItem> inventory = [
    InventoryItem(id: '1', ingredientId: 'egg', acquiredAt: DateTime.now()),
    InventoryItem(id: '2', ingredientId: 'rice', acquiredAt: DateTime.now()),
  ];
  bool isCombining = false;
  bool hasKimbap = false;
  bool showResult = false;

  void _combineIngredients() async {
    setState(() => isCombining = true);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: CombineAnimation(
          onComplete: () {
            setState(() {
              showResult = true;
              isCombining = false;
              hasKimbap = true;
              inventory.add(InventoryItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                ingredientId: 'kimbap',
                acquiredAt: DateTime.now(),
              ));
            });
            Navigator.of(context).pop();
          },
        ),
        contentPadding: const EdgeInsets.all(8),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  void _onResultTap() {
    setState(() {
      showResult = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('김밥을 인벤토리에서 확인하세요!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasEgg = inventory.any((item) => item.ingredientId == 'egg');
    final hasRice = inventory.any((item) => item.ingredientId == 'rice');
    final canCombine = hasEgg && hasRice && !hasKimbap;
    return Scaffold(
      appBar: AppBar(title: const Text('요리 조합')),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ingredientIcon('egg'),
                    const SizedBox(width: 16),
                    const Icon(Icons.add, size: 32),
                    const SizedBox(width: 16),
                    _ingredientIcon('rice'),
                    const SizedBox(width: 16),
                    const Icon(Icons.arrow_forward, size: 32),
                    const SizedBox(width: 16),
                    _ingredientIcon('kimbap'),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: canCombine && !isCombining ? _combineIngredients : null,
                  child: const Text('조합하기'),
                ),
                if (hasKimbap && !showResult)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text('김밥을 인벤토리에서 확인하세요!', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            if (showResult)
              GestureDetector(
                onTap: _onResultTap,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/kimbap.jpg', width: 120),
                      const SizedBox(height: 16),
                      const Text('김밥 완성!\n(클릭해서 닫기)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _ingredientIcon(String id) {
    final ingredient = sampleIngredients.firstWhere((i) => i.id == id);
    return Column(
      children: [
        Image.asset(ingredient.imageUrl, width: 48),
        const SizedBox(height: 4),
        Text(ingredient.name),
      ],
    );
  }
} 