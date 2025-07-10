import 'package:flutter/material.dart';
import '../inventory/inventory_screen.dart';
import '../recipe/recipe_screen.dart';
import '../location/location_check_screen.dart';
import '../acquisition/ingredient_acquisition_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('급식실 게이미피케이션'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Text(
              '급식실 게임 테스트',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '각 기능을 테스트해보세요!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildFeatureButton(
              context,
              '1. 급식실 & 시간 확인',
              '위치와 시간 조건 확인',
              Icons.location_on,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationCheckScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureButton(
              context,
              '2. 재료 획득',
              '랜덤 재료 획득 테스트',
              Icons.card_giftcard,
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const IngredientAcquisitionScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureButton(
              context,
              '3. 데이터베이스',
              '인벤토리/도감/순위/오늘의 재료',
              Icons.storage,
              Colors.orange,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureButton(
              context,
              '4. 재료 합성',
              '조합 및 도감 등록 테스트',
              Icons.restaurant,
              Colors.purple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecipeScreen()),
                );
              },
            ),
            const Spacer(),
            const Text(
              '오늘의 급식 시간: 11:30 ~ 13:00',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
} 