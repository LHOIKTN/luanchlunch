import 'package:flutter/material.dart';
import 'package:launchlunch/models/food.dart';
import 'dart:io';
import 'package:launchlunch/theme/app_colors.dart';

class FoodDetailModal extends StatelessWidget {
  final Food food;
  final void Function(Food) onIngredientTap;
  final VoidCallback onClose;
  final List<Food> allFoods; // 모든 음식 목록을 전달받음
  
  const FoodDetailModal({
    required this.food,
    required this.onIngredientTap,
    required this.onClose,
    required this.allFoods,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recipeFoods = food.recipes?.map((id) => allFoods.firstWhere((f) => f.id == id)).toList() ?? [];
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  food.imageUrl.startsWith('assets/') 
                    ? Image.asset(food.imageUrl, width: 80, height: 80, fit: BoxFit.contain)
                    : Image.file(File(food.imageUrl), width: 80, height: 80, fit: BoxFit.contain),
                  const SizedBox(height: 16),
                  Text(food.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondaryDark), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(
                    food.detail ?? '${food.name}에 대한 설명입니다. 다양한 요리에 활용할 수 있는 재료입니다.',
                    style: const TextStyle(fontSize: 14, color: AppColors.secondaryDark),
                    textAlign: TextAlign.center,
                  ),
                  if (recipeFoods.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('레시피', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.secondaryDark)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: recipeFoods.map((f) => GestureDetector(
                        onTap: () => onIngredientTap(f),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              f.imageUrl.startsWith('assets/') 
                                ? Image.asset(f.imageUrl, width: 40, height: 40)
                                : Image.file(File(f.imageUrl), width: 40, height: 40),
                              const SizedBox(height: 4),
                              Text(f.name, style: const TextStyle(fontSize: 12, color: AppColors.secondaryDark)),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton(onPressed: onClose, child: const Text('닫기')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 