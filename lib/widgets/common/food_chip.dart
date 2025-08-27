import 'package:flutter/material.dart';
import 'dart:io';
import '../../models/food.dart';
import '../../theme/app_colors.dart';
import '../../utils/device_helper.dart';

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
      padding: EdgeInsets.symmetric(
        horizontal: DeviceHelper.isTablet(context) ? 16.0 : 12.0,
        vertical: DeviceHelper.isTablet(context) ? 8.0 : 6.0,
      ),
      decoration: BoxDecoration(
        color: isAcquired
            ? AppColors.success.withOpacity(0.2)
            : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAcquired
              ? AppColors.success
              : AppColors.success.withOpacity(0.3),
          width: isAcquired ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) {
              // 태블릿용 크기 조정
              final iconSize = DeviceHelper.isTablet(context) ? 24.0 : 16.0;

              if (food.imageUrl.isNotEmpty) {
                if (food.imageUrl.startsWith('assets/')) {
                  // Assets 이미지
                  return Image.asset(
                    food.imageUrl,
                    width: iconSize,
                    height: iconSize,
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ FoodChip Assets 이미지 로드 실패: ${food.imageUrl}');
                      return Icon(
                        Icons.fastfood,
                        size: iconSize,
                        color: isAcquired
                            ? AppColors.success
                            : AppColors.success.withOpacity(0.7),
                      );
                    },
                  );
                } else if (food.imageUrl.startsWith('/')) {
                  // 로컬 파일 이미지
                  return Image.file(
                    File(food.imageUrl),
                    width: iconSize,
                    height: iconSize,
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ FoodChip 로컬 파일 이미지 로드 실패: ${food.imageUrl}');
                      return Icon(
                        Icons.fastfood,
                        size: iconSize,
                        color: isAcquired
                            ? AppColors.success
                            : AppColors.success.withOpacity(0.7),
                      );
                    },
                  );
                }
              }

              // 기본 아이콘 (이미지가 없거나 로드 실패 시)
              return Icon(
                Icons.fastfood,
                size: iconSize,
                color: isAcquired
                    ? AppColors.success
                    : AppColors.success.withOpacity(0.7),
              );
            },
          ),
          SizedBox(width: DeviceHelper.isTablet(context) ? 8.0 : 6.0),
          Text(
            food.name,
            style: TextStyle(
              fontSize: DeviceHelper.isTablet(context) ? 16.0 : 12.0,
              fontWeight: isAcquired ? FontWeight.bold : FontWeight.w500,
              color: isAcquired
                  ? AppColors.success
                  : AppColors.success.withOpacity(0.7),
            ),
          ),
          if (isAcquired) ...[
            SizedBox(width: DeviceHelper.isTablet(context) ? 6.0 : 4.0),
            Icon(
              Icons.check_circle,
              size: DeviceHelper.isTablet(context) ? 16.0 : 12.0,
              color: AppColors.success,
            ),
          ],
        ],
      ),
    );
  }
}
