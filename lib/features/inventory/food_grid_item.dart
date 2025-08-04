import 'package:flutter/material.dart';
import 'package:launchlunch/models/food.dart';
import 'dart:io';

class FoodGridItem extends StatelessWidget {
  final Food food;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const FoodGridItem({
    required this.food,
    required this.onTap,
    required this.onLongPress,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Builder(
                builder: (context) {
                  
                  // 파일 존재 여부 확인 (로컬 파일인 경우)
                  if (food.imageUrl.startsWith('/')) {
                    final file = File(food.imageUrl);
                    file.exists().then((exists) {
                      print('🖼️ 파일 존재 여부: $exists - ${food.imageUrl}');
                    });
                  }
                  
                  return food.imageUrl.startsWith('assets/') 
                    ? Image.asset(
                        food.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Assets 이미지 로드 실패: ${food.imageUrl}');
                          print('❌ 에러: $error');
                          return Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                      )
                    : Image.file(
                        File(food.imageUrl), // 이미 전체 경로가 저장되어 있음
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ 로컬 파일 이미지 로드 실패: ${food.imageUrl}');
                          print('❌ 파일 존재 여부: ${File(food.imageUrl).existsSync()}');
                          print('❌ 에러: $error');
                          return Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                      );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            food.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 