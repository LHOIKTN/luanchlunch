import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 색상들을 중앙에서 관리하는 클래스
class AppColors {
  // 기본 테마 색상 (새로운 색상 팔레트)
  static const Color primary = Color(0xFF768B5E);        // 중간 톤의 녹색
  static const Color primaryLight = Color(0xFFBFC4A4);   // 연한 녹색
  static const Color primaryDark = Color(0xFF41503F);    // 진한 녹색

  // 보조 색상들
  static const Color secondary = Color(0xFFBFC4A4);      // 연한 녹색
  static const Color secondaryLight = Color(0xFFE4E1DF); // 가장 연한 색
  static const Color secondaryDark = Color(0xFF27322A);  // 매우 진한 색

  // 배경 색상들 - 모두 제일 연한 색으로 변경
  static const Color background = Color(0xFFE4E1DF);     // 가장 연한 색을 배경으로
  static const Color surface = Color(0xFFE4E1DF);        // 가장 연한 색으로 변경
  static const Color cardBackground = Color(0xFFE4E1DF); // 가장 연한 색으로 변경

  // 텍스트 색상들
  static const Color textPrimary = Color(0xFF27322A);    // 가장 진한 색을 주 텍스트로
  static const Color textSecondary = Color(0xFF41503F);  // 진한 녹색을 보조 텍스트로
  static const Color textHint = Color(0xFF768B5E);       // 중간 톤을 힌트 텍스트로
  static const Color textWhite = Colors.white;

  // 상태 색상들
  static const Color success = Color(0xFF768B5E);        // 중간 톤 녹색을 성공 색으로
  static const Color error = Color(0xFFF44336);          // 기존 빨간색 유지
  static const Color warning = Color(0xFFFF9800);        // 기존 주황색 유지
  static const Color info = Color(0xFF2196F3);           // 기존 파란색 유지

  // 랭킹 메달 색상들
  static const Color gold = Color(0xFFFFD700);           // 기존 금색 유지
  static const Color silver = Color(0xFFC0C0C0);        // 기존 은색 유지
  static const Color bronze = Color(0xFFCD7F32);        // 기존 동색 유지

  // 그라데이션 색상들
  static const List<Color> primaryGradient = [
    Color(0xFFE4E1DF),  // 가장 연한 색
    Color(0xFFBFC4A4),  // 연한 녹색
  ];

  static const List<Color> cardGradient = [
    Color(0xFFBFC4A4),  // 연한 녹색
    Color(0xFF768B5E),  // 중간 톤 녹색
  ];

  static const List<Color> warningGradient = [
    Color(0xFFFFE0B2),
    Color(0xFFFFCC02),
  ];

  // 그림자 색상
  static Color shadow = const Color(0xFF27322A).withOpacity(0.2);  // 가장 진한 색을 그림자로
  static Color shadowLight = const Color(0xFF27322A).withOpacity(0.1);

  // 테두리 색상들
  static const Color borderLight = Color(0xFFBFC4A4);    // 연한 녹색
  static const Color borderMedium = Color(0xFF768B5E);   // 중간 톤 녹색
  static const Color borderDark = Color(0xFF41503F);     // 진한 녹색

  // 투명도가 적용된 색상들
  static Color primaryWithOpacity(double opacity) =>
      primary.withOpacity(opacity);
  static Color shadowWithOpacity(double opacity) =>
      const Color(0xFF27322A).withOpacity(opacity);
}
