import 'package:flutter/material.dart';
import 'package:launchlunch/models/meal.dart';
import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/theme/app_colors.dart';

class IngredientAcquisitionCard extends StatelessWidget {
  final DailyMeal meal;
  final List<Food> availableFoods;
  final VoidCallback? onAcquirePressed;

  const IngredientAcquisitionCard({
    super.key,
    required this.meal,
    required this.availableFoods,
    this.onAcquirePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(
                meal.isAcquired ? Icons.check_circle : Icons.shopping_basket,
                color: meal.isAcquired ? AppColors.success : AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                meal.isAcquired ? '획득한 재료' : '재료 획득',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (meal.isAcquired) ...[
            // 획득한 재료 표시
            if (availableFoods.isNotEmpty) ...[
              ...availableFoods.map((food) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            food.name,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  )),
            ] else ...[
              const Text(
                '획득한 재료가 없습니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ] else ...[
            // 획득하기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAcquirePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '재료 얻기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '급식 시간에 재료를 획득할 수 있습니다.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
