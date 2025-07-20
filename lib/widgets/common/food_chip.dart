import 'package:flutter/material.dart';
import '../../models/food.dart';

class FoodChip extends StatelessWidget {
  final Food food;

  const FoodChip({
    super.key,
    required this.food,
  });

  @override
  Widget build(BuildContext context) {
    final isAcquired = food.acquiredAt != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAcquired 
            ? const Color(0xFF4CAF50).withOpacity(0.2)
            : const Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAcquired 
              ? const Color(0xFF4CAF50)
              : const Color(0xFF4CAF50).withOpacity(0.3),
          width: isAcquired ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (food.imageUrl.isNotEmpty && food.imageUrl.startsWith('assets/'))
            Image.asset(
              food.imageUrl,
              width: 16,
              height: 16,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.fastfood,
                size: 16,
                color: isAcquired 
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF4CAF50).withOpacity(0.7),
              ),
            )
          else
            Icon(
              Icons.fastfood,
              size: 16,
              color: isAcquired 
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF4CAF50).withOpacity(0.7),
            ),
          const SizedBox(width: 6),
          Text(
            food.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isAcquired ? FontWeight.bold : FontWeight.w500,
              color: isAcquired 
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF4CAF50).withOpacity(0.7),
            ),
          ),
          if (isAcquired) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.check_circle,
              size: 12,
              color: Color(0xFF4CAF50),
            ),
          ],
        ],
      ),
    );
  }
}
