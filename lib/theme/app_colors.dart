import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상들을 중앙에서 관리하는 클래스
class AppColors {
  // 기본 테마 색상 (연보라색)
  static const Color primary = Color(0xFF9C27B0);
  static const Color primaryLight = Color(0xFFE1BEE7);
  static const Color primaryDark = Color(0xFF7B1FA2);

  // 보조 색상들
  static const Color secondary = Color(0xFFE1BEE7);
  static const Color secondaryLight = Color(0xFFF3E5F5);
  static const Color secondaryDark = Color(0xFFC2185B);

  // 배경 색상들
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color cardBackground = Colors.white;

  // 텍스트 색상들
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color textWhite = Colors.white;

  // 상태 색상들
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // 랭킹 메달 색상들
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  // 그라데이션 색상들
  static const List<Color> primaryGradient = [
    Color(0xFFE1BEE7),
    Color(0xFFF3E5F5),
  ];

  static const List<Color> cardGradient = [
    Color(0xFFF3E5F5),
    Color(0xFFE1BEE7),
  ];

  static const List<Color> warningGradient = [
    Color(0xFFFFE0B2),
    Color(0xFFFFCC02),
  ];

  // 그림자 색상
  static Color shadow = Colors.grey.withOpacity(0.2);
  static Color shadowLight = Colors.grey.withOpacity(0.1);

  // 테두리 색상들
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFBDBDBD);
  static const Color borderDark = Color(0xFF9E9E9E);

  // 투명도가 적용된 색상들
  static Color primaryWithOpacity(double opacity) =>
      primary.withOpacity(opacity);
  static Color shadowWithOpacity(double opacity) =>
      Colors.grey.withOpacity(opacity);
}
