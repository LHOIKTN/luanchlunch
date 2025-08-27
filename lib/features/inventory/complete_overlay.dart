import 'package:flutter/material.dart';
import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/theme/app_colors.dart';
import 'package:launchlunch/utils/device_helper.dart';
import 'dart:io';

// CompleteOverlay를 StatefulWidget으로 변경
class CompleteOverlay extends StatefulWidget {
  final Food food;
  final VoidCallback onClose;
  final VoidCallback onLongPress;
  final List<Food> allFoods; // 모든 음식 목록 추가

  const CompleteOverlay({
    required this.food,
    required this.onClose,
    required this.onLongPress,
    required this.allFoods, // 필수 매개변수로 추가
    Key? key,
  }) : super(key: key);

  @override
  State<CompleteOverlay> createState() => _CompleteOverlayState();
}

class _CompleteOverlayState extends State<CompleteOverlay> {
  @override
  Widget build(BuildContext context) {
    final recipeFoods = widget.food.recipes
            ?.map((id) => widget.allFoods.firstWhere((f) => f.id == id,
                orElse: () => widget.allFoods.first))
            .toList() ??
        [];

    return GestureDetector(
      onTap: widget.onClose,
      onLongPress: widget.onLongPress,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // 내부 카드 탭 방지
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 완성 배지
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DeviceHelper.isTablet(context) ? 24.0 : 20.0,
                      vertical: DeviceHelper.isTablet(context) ? 12.0 : 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🎉 조합 완성!',
                      style: TextStyle(
                        fontSize: DeviceHelper.isTablet(context) ? 20.0 : 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(
                      height: DeviceHelper.isTablet(context) ? 32.0 : 24.0),

                  // 음식 이미지
                  widget.food.imageUrl.startsWith('assets/')
                      ? Image.asset(widget.food.imageUrl,
                          width: DeviceHelper.isTablet(context) ? 120.0 : 80.0,
                          height: DeviceHelper.isTablet(context) ? 120.0 : 80.0,
                          fit: BoxFit.contain)
                      : Image.file(File(widget.food.imageUrl),
                          width: DeviceHelper.isTablet(context) ? 120.0 : 80.0,
                          height: DeviceHelper.isTablet(context) ? 120.0 : 80.0,
                          fit: BoxFit.contain),
                  SizedBox(
                      height: DeviceHelper.isTablet(context) ? 20.0 : 16.0),

                  // 음식 이름
                  Text(
                    widget.food.name,
                    style: TextStyle(
                      fontSize: DeviceHelper.isTablet(context) ? 28.0 : 20.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                      height: DeviceHelper.isTablet(context) ? 16.0 : 12.0),

                  // 음식 설명
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: DeviceHelper.isTablet(context) ? 400.0 : 300.0,
                    ),
                    child: Text(
                      widget.food.detail ??
                          '${widget.food.name}에 대한 설명입니다. 다양한 요리에 활용할 수 있는 재료입니다.',
                      style: TextStyle(
                        fontSize: DeviceHelper.isTablet(context) ? 18.0 : 14.0,
                        color: AppColors.secondaryDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // 레시피 정보 (재료들)
                  if (recipeFoods.isNotEmpty) ...[
                    SizedBox(
                        height: DeviceHelper.isTablet(context) ? 28.0 : 20.0),
                    Text(
                      '레시피',
                      style: TextStyle(
                        fontSize: DeviceHelper.isTablet(context) ? 20.0 : 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                    SizedBox(
                        height: DeviceHelper.isTablet(context) ? 16.0 : 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: recipeFoods
                          .map((f) => GestureDetector(
                                onTap: () {}, // 조합 완성 시에는 재료 탭 비활성화
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: DeviceHelper.isTablet(context)
                                        ? 12.0
                                        : 8.0,
                                  ),
                                  child: Column(
                                    children: [
                                      f.imageUrl.startsWith('assets/')
                                          ? Image.asset(
                                              f.imageUrl,
                                              width:
                                                  DeviceHelper.isTablet(context)
                                                      ? 48.0
                                                      : 40.0,
                                              height:
                                                  DeviceHelper.isTablet(context)
                                                      ? 48.0
                                                      : 40.0,
                                            )
                                          : Image.file(
                                              File(f.imageUrl),
                                              width:
                                                  DeviceHelper.isTablet(context)
                                                      ? 48.0
                                                      : 40.0,
                                              height:
                                                  DeviceHelper.isTablet(context)
                                                      ? 48.0
                                                      : 40.0,
                                            ),
                                      SizedBox(
                                          height: DeviceHelper.isTablet(context)
                                              ? 6.0
                                              : 4.0),
                                      Text(
                                        f.name,
                                        style: TextStyle(
                                          fontSize:
                                              DeviceHelper.isTablet(context)
                                                  ? 14.0
                                                  : 12.0,
                                          color: AppColors.secondaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],

                  SizedBox(
                      height: DeviceHelper.isTablet(context) ? 32.0 : 16.0),
                  TextButton(
                    onPressed: widget.onClose,
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
