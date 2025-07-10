import 'package:flutter/material.dart';
import 'dart:math';
import '../../data/models/ingredient.dart';
import '../../data/models/inventory.dart';

class IngredientAcquisitionScreen extends StatefulWidget {
  const IngredientAcquisitionScreen({super.key});

  @override
  State<IngredientAcquisitionScreen> createState() => _IngredientAcquisitionScreenState();
}

class _IngredientAcquisitionScreenState extends State<IngredientAcquisitionScreen> {
  // 샘플 재료 리스트 (오늘의 랜덤 재료)
  final List<Ingredient> todayIngredients = [
    Ingredient(id: 'Egg', name: '계란', imageUrl: 'assets/egg.jpg'),
    Ingredient(id: 'Chicken', name: '닭고기', imageUrl: 'assets/Chicken.png'),
    Ingredient(id: 'Blueberry', name: '블루베리', imageUrl: 'assets/Blueberry.png'),
    Ingredient(id: 'Lettuce', name: '양상추', imageUrl: 'assets/Lettuce.png'),
    Ingredient(id: 'Napa Cabbage', name: '배추', imageUrl: 'assets/NapaCabbage.png'),
    
  ];

  // 획득한 재료 목록
  List<InventoryItem> acquiredIngredients = [];
  Ingredient? lastAcquiredIngredient;
  bool isAcquiring = false;

  @override
  void initState() {
    super.initState();
    // 초기 재료 2개 획득 (테스트용)
    _acquireRandomIngredient();
    _acquireRandomIngredient();
  }

  void _acquireRandomIngredient() {
    if (isAcquiring) return;

    setState(() {
      isAcquiring = true;
    });

    // 랜덤 재료 선택
    final random = Random();
    final randomIngredient = todayIngredients[random.nextInt(todayIngredients.length)];

    // 애니메이션 효과를 위한 딜레이
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        lastAcquiredIngredient = randomIngredient;
        acquiredIngredients.add(InventoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          ingredientId: randomIngredient.id,
          acquiredAt: DateTime.now(),
        ));
        isAcquiring = false;
      });

      // 획득 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${randomIngredient.name}을(를) 획득했습니다!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _clearAcquiredIngredients() {
    setState(() {
      acquiredIngredients.clear();
      lastAcquiredIngredient = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('재료 획득'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTodayIngredientsCard(),
            const SizedBox(height: 24),
            _buildAcquisitionButton(),
            const SizedBox(height: 24),
            _buildLastAcquiredCard(),
            const SizedBox(height: 24),
            _buildAcquiredListCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayIngredientsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '오늘의 랜덤 재료',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('총 ${todayIngredients.length}개의 재료 중 랜덤 획득'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: todayIngredients.map((ingredient) {
                return Chip(
                  label: Text(ingredient.name),
                  avatar: Image.asset(ingredient.imageUrl, width: 20),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcquisitionButton() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '재료 획득',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: isAcquiring ? null : _acquireRandomIngredient,
              icon: isAcquiring 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.card_giftcard),
              label: Text(isAcquiring ? '획득 중...' : '랜덤 재료 획득'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '조건: 급식실 근처 + 급식시간',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastAcquiredCard() {
    if (lastAcquiredIngredient == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '방금 획득한 재료',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(lastAcquiredIngredient!.imageUrl, width: 48),
                const SizedBox(width: 16),
                Text(
                  lastAcquiredIngredient!.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcquiredListCard() {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.inventory, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    '획득한 재료 목록',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearAcquiredIngredients,
                    child: const Text('초기화'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (acquiredIngredients.isEmpty)
                const Center(
                  child: Text(
                    '획득한 재료가 없습니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: acquiredIngredients.length,
                    itemBuilder: (context, index) {
                      final item = acquiredIngredients[index];
                      final ingredient = todayIngredients.firstWhere(
                        (i) => i.id == item.ingredientId,
                      );
                      return ListTile(
                        leading: Image.asset(ingredient.imageUrl, width: 32),
                        title: Text(ingredient.name),
                        subtitle: Text(
                          '획득: ${item.acquiredAt.hour.toString().padLeft(2, '0')}:${item.acquiredAt.minute.toString().padLeft(2, '0')}',
                        ),
                        trailing: Text('${index + 1}번째'),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 