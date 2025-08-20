import 'package:flutter/material.dart';
import 'package:launchlunch/models/meal.dart';
import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/theme/app_colors.dart';
import 'package:launchlunch/utils/date_helper.dart';
import 'package:launchlunch/utils/developer_mode.dart';

class IngredientAcquisitionCard extends StatefulWidget {
  final DailyMeal meal;
  final List<Food> availableFoods;
  final VoidCallback? onAcquirePressed;

  const IngredientAcquisitionCard({
    super.key,
    required this.meal,
    required this.availableFoods,
    this.onAcquirePressed,
  });

  @override
  State<IngredientAcquisitionCard> createState() =>
      _IngredientAcquisitionCardState();
}

class _IngredientAcquisitionCardState extends State<IngredientAcquisitionCard> {
  bool _isDeveloperModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadDeveloperModeStatus();
  }

  void _loadDeveloperModeStatus() async {
    final isEnabled = await DeveloperMode.isEnabled();
    setState(() {
      _isDeveloperModeEnabled = isEnabled;
    });
  }

  /// 날짜 제한 확인
  bool _isDateRestrictionEnabled() {
    // 개발자 모드가 활성화되어 있으면 날짜 제한 해제
    if (_isDeveloperModeEnabled) {
      return false;
    }
    return true; // 개발자 모드가 비활성화되어 있으면 날짜 제한 적용
  }

  /// 오늘 날짜의 급식인지 확인
  bool _isTodayMeal() {
    if (!_isDateRestrictionEnabled()) {
      return true; // 개발자 모드면 모든 날짜 허용
    }
    return DateHelper.isTodayMeal(widget.meal.lunchDate);
  }

  /// 획득 버튼 활성화 여부
  bool _isAcquireButtonEnabled() {
    // 이미 획득했으면 비활성화
    if (widget.meal.isAcquired) {
      return false;
    }

    // 획득 가능한 재료가 없으면 비활성화
    if (widget.availableFoods.isEmpty) {
      return false;
    }

    // 날짜 제한 확인
    return _isTodayMeal();
  }

  String _getButtonText() {
    if (widget.availableFoods.isEmpty) {
      return '재료가 없습니다.';
    }
    if (!_isTodayMeal()) {
      return '오늘 날짜가 아닙니다';
    }
    return '재료 얻기';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _isTodayMeal();
    final isButtonEnabled = _isAcquireButtonEnabled();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.meal.isAcquired
                    ? Icons.check_circle
                    : Icons.shopping_basket,
                color: widget.meal.isAcquired
                    ? AppColors.success
                    : AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                widget.meal.isAcquired ? '획득한 재료' : '재료 획득',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.meal.isAcquired) ...[
            // 획득한 재료 표시
            if (widget.availableFoods.isNotEmpty) ...[
              ...widget.availableFoods.map((food) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            food.name,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  )),
            ] else ...[
              const Text(
                '획득한 재료가 없습니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.secondaryDark,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ] else ...[
            // 획득하기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isButtonEnabled ? widget.onAcquirePressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isButtonEnabled ? AppColors.primary : Colors.grey,
                  foregroundColor: AppColors.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _getButtonText(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
