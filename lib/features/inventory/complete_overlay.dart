import 'package:flutter/material.dart';
import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/theme/app_colors.dart';
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
    final recipeFoods = widget.food.recipes?.map((id) => 
      widget.allFoods.firstWhere((f) => f.id == id, orElse: () => widget.allFoods.first)
    ).toList() ?? [];
    
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
                    offset: const Offset(0, 5)
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 완성 배지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🎉 조합 완성!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 음식 이미지
                  widget.food.imageUrl.startsWith('assets/')
                      ? Image.asset(widget.food.imageUrl, width: 100, height: 100, fit: BoxFit.contain)
                      : Image.file(File(widget.food.imageUrl), width: 100, height: 100, fit: BoxFit.contain),
                  const SizedBox(height: 16),
                  
                  // 음식 이름
                  Text(
                    widget.food.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // 음식 설명
                  Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      widget.food.detail ?? '${widget.food.name}에 대한 설명입니다. 다양한 요리에 활용할 수 있는 재료입니다.',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // 레시피 정보 (재료들)
                  if (recipeFoods.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      '레시피',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      children: recipeFoods.map((f) => Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            f.imageUrl.startsWith('assets/')
                                ? Image.asset(f.imageUrl, width: 32, height: 32)
                                : Image.file(File(f.imageUrl), width: 32, height: 32),
                            const SizedBox(height: 4),
                            Text(
                              f.name,
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  const Text(
                    '탭하여 계속',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
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
