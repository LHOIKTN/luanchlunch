import 'package:flutter/material.dart';
import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/utils/device_helper.dart';
import 'package:launchlunch/utils/image_validator.dart';
import 'dart:io';

class FoodGridItem extends StatefulWidget {
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
  State<FoodGridItem> createState() => _FoodGridItemState();
}

class _FoodGridItemState extends State<FoodGridItem> {
  bool _isImageValid = true;
  String _currentImageUrl = '';

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.food.imageUrl;
    _validateImage();
  }

  @override
  void didUpdateWidget(FoodGridItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.food.imageUrl != widget.food.imageUrl) {
      _currentImageUrl = widget.food.imageUrl;
      _validateImage();
    }
  }

  Future<void> _validateImage() async {
    final imageValidator = ImageValidator();
    final status = await imageValidator.checkImageStatus(widget.food);

    if (!status['isValid']) {
      print('⚠️ 이미지 유효하지 않음: ${widget.food.name}');
      // 이미지 복구 시도
      await imageValidator.validateAndRepairImages();
      // 복구 후 다시 확인
      final newStatus = await imageValidator.checkImageStatus(widget.food);
      if (newStatus['isValid'] && mounted) {
        setState(() {
          _currentImageUrl = widget.food.imageUrl;
          _isImageValid = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 태블릿용 크기 조정 - 이미지와 텍스트는 2배로 확대
    final imageSize = DeviceHelper.isTablet(context) ? 96.0 : 48.0; // 2배 확대
    final borderRadius = DeviceHelper.getScaledSize(context, 12);
    final padding = DeviceHelper.getScaledSize(context, 12);
    final spacing =
        DeviceHelper.isTablet(context) ? 12.0 : 4.0; // 텍스트가 커져서 간격도 늘림
    final fontSize = DeviceHelper.isTablet(context) ? 24.0 : 12.0; // 2배 확대

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Builder(
                builder: (context) {
                  // 파일 존재 여부 확인 (로컬 파일인 경우)
                  if (_currentImageUrl.startsWith('/')) {
                    final file = File(_currentImageUrl);
                    file.exists().then((exists) {
                      print('🖼️ 파일 존재 여부: $exists - $_currentImageUrl');
                    });
                  }

                  return _currentImageUrl.startsWith('assets/')
                      ? Image.asset(
                          _currentImageUrl,
                          width: imageSize,
                          height: imageSize,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ Assets 이미지 로드 실패: $_currentImageUrl');
                            print('❌ 에러: $error');
                            return Container(
                              width: imageSize,
                              height: imageSize,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            );
                          },
                        )
                      : Image.file(
                          File(_currentImageUrl), // 이미 전체 경로가 저장되어 있음
                          width: imageSize,
                          height: imageSize,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ 로컬 파일 이미지 로드 실패: $_currentImageUrl');
                            print(
                                '❌ 파일 존재 여부: ${File(_currentImageUrl).existsSync()}');
                            print('❌ 에러: $error');
                            return Container(
                              width: imageSize,
                              height: imageSize,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            );
                          },
                        );
                },
              ),
            ),
          ),
          SizedBox(height: spacing),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: DeviceHelper.isTablet(context) ? 8.0 : 4.0,
              vertical: DeviceHelper.isTablet(context) ? 4.0 : 2.0,
            ),
            child: Text(
              widget.food.name,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2, // 태블릿에서는 2줄까지 허용
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
