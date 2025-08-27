import 'package:flutter/material.dart';
import 'package:launchlunch/models/food.dart';
import 'package:collection/collection.dart';
import 'dart:io';
import 'package:launchlunch/theme/app_colors.dart';
import 'package:launchlunch/utils/device_helper.dart';

class CombinationBox extends StatelessWidget {
  final List<Food> selectedFoods;
  final List<Food> allFoods;
  final List<Food> availableFoods; // 이미 획득한 재료들
  final Food? resultFood;
  final bool isCombinationFailed;
  final Function(Food) onRemoveFood;
  final VoidCallback onClearCombination;
  final Function(Food) onCompleteRecipe;

  const CombinationBox({
    required this.selectedFoods,
    required this.allFoods,
    required this.availableFoods,
    required this.resultFood,
    required this.isCombinationFailed,
    required this.onRemoveFood,
    required this.onClearCombination,
    required this.onCompleteRecipe,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 태블릿용 크기 조정
    final boxSize = DeviceHelper.getScaledBoxSize(context, 60, 60);
    final iconSize = DeviceHelper.getScaledSize(context, 40);
    final margin = DeviceHelper.getScaledSize(context, 4);
    final padding = DeviceHelper.getScaledSize(context, 6);
    final borderRadius = DeviceHelper.getScaledSize(context, 12);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 0),
      color: AppColors.background,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(3, (i) {
                if (i < selectedFoods.length) {
                  final food = selectedFoods[i];
                  return GestureDetector(
                    onTap: () => onRemoveFood(food),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: margin),
                      padding: EdgeInsets.all(padding),
                      width: boxSize.width,
                      height: boxSize.height,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(borderRadius),
                        border: Border.all(color: AppColors.secondary),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          food.imageUrl.startsWith('assets/')
                              ? Image.asset(food.imageUrl, height: iconSize)
                              : Image.file(File(food.imageUrl),
                                  height: iconSize),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: margin),
                    width: boxSize.width,
                    height: boxSize.height,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(color: AppColors.borderMedium),
                    ),
                  );
                }
              }),
              SizedBox(width: DeviceHelper.getScaledSize(context, 12)),
              // 조합/완성품/X 영역
              Builder(
                builder: (context) {
                  final canCombine = selectedFoods.length >= 2;
                  Food? matchedRecipe;
                  bool isAlreadyAcquired = false;

                  if (canCombine) {
                    // 조합된 재료 id 리스트
                    final selectedIds = selectedFoods.map((f) => f.id).toList()
                      ..sort();
                    print('🔍 [조합 매칭] 선택된 재료 IDs: $selectedIds');

                    int recipeCheckCount = 0;
                    for (final food in allFoods) {
                      if (food.recipes != null) {
                        recipeCheckCount++;
                        final recipeIds = List<int>.from(food.recipes!)..sort();
                        print(
                            '🔎 [조합 매칭] 음식 ${food.id}(${food.name}) 레시피 확인: $recipeIds');

                        if (recipeIds.length == selectedIds.length &&
                            const ListEquality()
                                .equals(recipeIds, selectedIds)) {
                          matchedRecipe = food;
                          // 이미 획득한 재료인지 확인
                          isAlreadyAcquired =
                              availableFoods.any((f) => f.id == food.id);
                          print(
                              '✅ [조합 매칭] 매칭 성공! 음식 ${food.id}(${food.name}), 이미 획득: $isAlreadyAcquired');
                          break;
                        }
                      }
                    }

                    print(
                        '📊 [조합 매칭] 총 ${recipeCheckCount}개의 레시피 확인, 매칭 결과: ${matchedRecipe?.name ?? '없음'}');

                    if (matchedRecipe == null) {
                      print('❌ [조합 매칭] 선택된 재료 $selectedIds로 만들 수 있는 음식이 없습니다.');
                    }
                  }
                  // 조합 버튼을 눌렀을 때의 결과 상태
                  // 조합 인벤토리에 변화가 있으면 결과 상태를 초기화
                  bool showResult =
                      (resultFood != null || isCombinationFailed) &&
                          selectedFoods.length >= 2;
                  if (showResult) {
                    if (resultFood != null && matchedRecipe != null) {
                      // 완성품 노출
                      return Container(
                        width: boxSize.width,
                        height: boxSize.height,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(borderRadius),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: matchedRecipe.imageUrl.startsWith('assets/')
                            ? Image.asset(matchedRecipe.imageUrl,
                                height: iconSize)
                            : Image.file(File(matchedRecipe.imageUrl),
                                height: iconSize),
                      );
                    } else {
                      // X 표시
                      return GestureDetector(
                        onTap: onClearCombination,
                        child: Container(
                          width: boxSize.width,
                          height: boxSize.height,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(borderRadius),
                            border: Border.all(color: AppColors.error),
                          ),
                          child: Icon(
                            Icons.close,
                            color: AppColors.error,
                            size: DeviceHelper.getScaledIconSize(context, 40),
                          ),
                        ),
                      );
                    }
                  } else if (canCombine &&
                      matchedRecipe != null &&
                      isAlreadyAcquired) {
                    // 이미 획득한 재료로 만들 수 있는 완성품 - 조합 비활성화
                    return Container(
                      width: boxSize.width,
                      height: boxSize.height,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(borderRadius),
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      ),
                      child: matchedRecipe.imageUrl.startsWith('assets/')
                          ? Image.asset(matchedRecipe.imageUrl,
                              height: iconSize)
                          : Image.file(File(matchedRecipe.imageUrl),
                              height: iconSize),
                    );
                  } else if (canCombine) {
                    // cooking.png 활성화(컬러, 하늘색 배경, 작게)
                    final cookingIconSize =
                        DeviceHelper.getScaledSize(context, 28);
                    return GestureDetector(
                      onTap: () async {
                        if (matchedRecipe != null) {
                          onCompleteRecipe(matchedRecipe);
                        } else {
                          // 조합 실패 - isCombinationFailed를 true로 설정
                          onCompleteRecipe(
                              Food(id: -1, name: '조합 실패', imageUrl: ''));
                        }
                      },
                      child: Container(
                        width: boxSize.width,
                        height: boxSize.height,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(borderRadius),
                          border: Border.all(color: AppColors.secondaryDark),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(padding),
                          child: Image.asset(
                            'assets/images/cooking.png',
                            width: cookingIconSize,
                            height: cookingIconSize,
                          ),
                        ),
                      ),
                    );
                  } else {
                    // 비활성화(흑백, 투명 배경, 작게)
                    final cookingIconSize =
                        DeviceHelper.getScaledSize(context, 28);
                    return Container(
                      width: boxSize.width,
                      height: boxSize.height,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(borderRadius),
                        border: Border.all(color: AppColors.secondaryDark),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]),
                          child: Image.asset(
                            'assets/images/cooking.png',
                            width: cookingIconSize,
                            height: cookingIconSize,
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
