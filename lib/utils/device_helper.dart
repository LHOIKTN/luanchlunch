import 'package:flutter/material.dart';

class DeviceHelper {
  /// 화면이 태블릿인지 확인
  static bool isTablet(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return shortestSide >= 600;
  }

  /// 태블릿일 때 1.5배 크기로 확대된 값을 반환
  static double getScaledSize(BuildContext context, double baseSize) {
    return isTablet(context) ? baseSize * 1.5 : baseSize;
  }

  /// 태블릿일 때 1.5배 크기로 확대된 아이콘 크기를 반환
  static double getScaledIconSize(BuildContext context, double baseIconSize) {
    return isTablet(context) ? baseIconSize * 1.5 : baseIconSize;
  }

  /// 태블릿일 때 1.5배 크기로 확대된 폰트 크기를 반환
  static double getScaledFontSize(BuildContext context, double baseFontSize) {
    return isTablet(context) ? baseFontSize * 1.5 : baseFontSize;
  }

  /// 태블릿일 때 1.5배 크기로 확대된 박스 크기를 반환 (width, height)
  static Size getScaledBoxSize(
      BuildContext context, double width, double height) {
    final scale = isTablet(context) ? 1.5 : 1.0;
    return Size(width * scale, height * scale);
  }
}
