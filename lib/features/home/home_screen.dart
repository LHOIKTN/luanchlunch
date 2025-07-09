import 'package:flutter/material.dart';
import '../inventory/inventory_screen.dart';
import '../recipe/recipe_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('급식실 게임 홈')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('오늘의 급식 시간: 11:30 ~ 13:00'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                );
              },
              child: const Text('내 재료 보관함'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecipeScreen()),
                );
              },
              child: const Text('요리 조합'),
            ),
          ],
        ),
      ),
    );
  }
} 