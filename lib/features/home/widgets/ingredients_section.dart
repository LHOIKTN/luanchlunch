import 'package:flutter/material.dart';
import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/widgets/common/food_chip.dart';
import 'package:launchlunch/theme/app_colors.dart';

class IngredientsSection extends StatelessWidget {
  final List<Food> availableFoods;

  const IngredientsSection({
    super.key,
    required this.availableFoods,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '획득 가능한 재료',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryDark,
          ),
        ),
        const SizedBox(height: 12),
        if (availableFoods.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${availableFoods.length}개의 재료',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${availableFoods.where((f) => f.acquiredAt != null).length}개 획득)',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableFoods
                      .map((food) => FoodChip(food: food))
                      .toList(),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
                          child: const Text(
                '아직 획득한 재료가 없습니다.\n조합 탭에서 재료를 획득해보세요!',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.secondaryDark,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ),
        ],
      ],
    );
  }
} 