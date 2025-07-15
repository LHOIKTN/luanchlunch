import 'package:flutter/material.dart';
import 'package:launchlunch/models/food.dart';
import 'package:collection/collection.dart';
import 'dart:io';

class CombinationBox extends StatelessWidget {
  final List<Food> selectedFoods;
  final List<Food> allFoods;
  final Food? resultFood;
  final bool isCombinationFailed;
  final Function(Food) onRemoveFood;
  final VoidCallback onClearCombination;
  final Function(Food) onCompleteRecipe;

  const CombinationBox({
    required this.selectedFoods,
    required this.allFoods,
    required this.resultFood,
    required this.isCombinationFailed,
    required this.onRemoveFood,
    required this.onClearCombination,
    required this.onCompleteRecipe,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      color: Colors.grey.shade100,
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
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(6),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        food.imageUrl.startsWith('assets/') 
                          ? Image.asset(food.imageUrl, height: 32)
                          : Image.file(File(food.imageUrl), height: 32),
                      ],
                    ),
                  ),
                );
              } else {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Image.asset(
                    'assets/images/cooking.png',
                    width: 32,
                    height: 32,
                    color: Colors.white,
                  ),
                );
              }
            }),
            const SizedBox(width: 12),
            // 조합/완성품/X 영역
            Builder(
              builder: (context) {
                final canCombine = selectedFoods.length >= 2;
                Food? matchedRecipe;
                if (canCombine) {
                  // 조합된 재료 id 리스트
                  final selectedIds = selectedFoods.map((f) => f.id).toList()..sort();
                  for (final food in allFoods) {
                    if (food.recipes != null) {
                      final recipeIds = List<int>.from(food.recipes!)..sort();
                      if (recipeIds.length == selectedIds.length &&
                          const ListEquality().equals(recipeIds, selectedIds)) {
                        matchedRecipe = food;
                        break;
                      }
                    }
                  }
                }
                // 조합 버튼을 눌렀을 때의 결과 상태
                bool showResult = resultFood != null || isCombinationFailed;
                if (showResult) {
                  if (resultFood != null && matchedRecipe != null) {
                    // 완성품 노출
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: matchedRecipe.imageUrl.startsWith('assets/') 
                        ? Image.asset(matchedRecipe.imageUrl, height: 48)
                        : Image.file(File(matchedRecipe.imageUrl), height: 48),
                    );
                  } else {
                    // X 표시
                    return GestureDetector(
                      onTap: onClearCombination,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    );
                  }
                } else if (canCombine) {
                  // cooking.png 활성화(컬러, 하늘색 배경, 작게)
                  return GestureDetector(
                    onTap: () async {
                      if (matchedRecipe != null) {
                        onCompleteRecipe(matchedRecipe);
                      }
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/images/cooking.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  );
                } else {
                  // 비활성화(흑백, 투명 배경, 작게)
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0, 0, 0, 1, 0,
                      ]),
                      child: Image.asset(
                        'assets/images/cooking.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
} 