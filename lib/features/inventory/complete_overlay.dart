import 'package:flutter/material.dart';
import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/theme/app_colors.dart';
import 'dart:io';

// CompleteOverlay를 StatefulWidget으로 변경
class CompleteOverlay extends StatefulWidget {
  final Food food;
  final VoidCallback onClose;
  final VoidCallback onLongPress;
  const CompleteOverlay({
    required this.food,
    required this.onClose,
    required this.onLongPress,
    Key? key,
  }) : super(key: key);

  @override
  State<CompleteOverlay> createState() => _CompleteOverlayState();
}

class _CompleteOverlayState extends State<CompleteOverlay> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      onLongPress: widget.onLongPress,
      child: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.food.name,
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              const SizedBox(height: 40),
              widget.food.imageUrl.startsWith('assets/')
                  ? Image.asset(widget.food.imageUrl, width: 120, height: 120)
                  : Image.file(File(widget.food.imageUrl),
                      width: 120, height: 120),
              const SizedBox(height: 40),
              const Text('탭하여 계속',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
