import 'package:flutter/material.dart';
import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/utils/device_helper.dart';
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
    final recipeFoods = food.recipes
            ?.map((id) => allFoods.firstWhere((f) => f.id == id))
            .toList() ??
        [];
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin:
                  EdgeInsets.all(DeviceHelper.isTablet(context) ? 48.0 : 32.0),
              padding:
                  EdgeInsets.all(DeviceHelper.isTablet(context) ? 32.0 : 24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  food.imageUrl.startsWith('assets/')
                      ? Image.asset(food.imageUrl,
                          width: DeviceHelper.isTablet(context) ? 120.0 : 80.0,
                          height: DeviceHelper.isTablet(context) ? 120.0 : 80.0,
                          fit: BoxFit.contain)
                      : Image.file(File(food.imageUrl),
                          width: DeviceHelper.isTablet(context) ? 120.0 : 80.0,
                          height: DeviceHelper.isTablet(context) ? 120.0 : 80.0,
                          fit: BoxFit.contain),
                  SizedBox(
                      height: DeviceHelper.isTablet(context) ? 20.0 : 16.0),
                  Text(food.name,
                      style: TextStyle(
                          fontSize:
                              DeviceHelper.isTablet(context) ? 28.0 : 20.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryDark),
                      textAlign: TextAlign.center),
                  SizedBox(
                      height: DeviceHelper.isTablet(context) ? 16.0 : 12.0),
                  Text(
                    food.detail ??
                        '${food.name}에 대한 설명입니다. 다양한 요리에 활용할 수 있는 재료입니다.',
                    style: TextStyle(
                        fontSize: DeviceHelper.isTablet(context) ? 18.0 : 14.0,
                        color: AppColors.secondaryDark),
                    textAlign: TextAlign.center,
                  ),
                  if (recipeFoods.isNotEmpty) ...[
                    SizedBox(
                        height: DeviceHelper.isTablet(context) ? 28.0 : 20.0),
                    Text('레시피',
                        style: TextStyle(
                            fontSize:
                                DeviceHelper.isTablet(context) ? 20.0 : 16.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondaryDark)),
                    SizedBox(
                        height: DeviceHelper.isTablet(context) ? 12.0 : 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: recipeFoods
                          .map((f) => GestureDetector(
                                onTap: () => onIngredientTap(f),
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: DeviceHelper.isTablet(context)
                                        ? 12.0
                                        : 8.0,
                                  ),
                                  child: Column(
                                    children: [
                                      f.imageUrl.startsWith('assets/')
                                          ? Image.asset(f.imageUrl,
                                              width:
                                                  DeviceHelper.isTablet(context)
                                                      ? 48.0
                                                      : 40.0,
                                              height:
                                                  DeviceHelper.isTablet(context)
                                                      ? 48.0
                                                      : 40.0)
                                          : Image.file(File(f.imageUrl),
                                              width:
                                                  DeviceHelper.isTablet(context)
                                                      ? 48.0
                                                      : 40.0,
                                              height:
                                                  DeviceHelper.isTablet(context)
                                                      ? 48.0
                                                      : 40.0),
                                      SizedBox(
                                          height: DeviceHelper.isTablet(context)
                                              ? 6.0
                                              : 4.0),
                                      Text(f.name,
                                          style: TextStyle(
                                              fontSize:
                                                  DeviceHelper.isTablet(context)
                                                      ? 14.0
                                                      : 12.0,
                                              color: AppColors.secondaryDark)),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                  SizedBox(
                      height: DeviceHelper.isTablet(context) ? 24.0 : 16.0),
                  TextButton(
                    onPressed: onClose,
                    child: Text(
                      '닫기',
                      style: TextStyle(
                        fontSize: DeviceHelper.isTablet(context) ? 18.0 : 16.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
