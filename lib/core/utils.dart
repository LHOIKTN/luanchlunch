import 'dart:math';

/// Haversine 공식으로 두 좌표 간 거리(m) 계산
/// [lat1, lon1, lat2, lon2]는 모두 degree 단위
/// 반환값: meter

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double R = 6371000; // 지구 반지름(m)
  final double dLat = _deg2rad(lat2 - lat1);
  final double dLon = _deg2rad(lon2 - lon1);
  final double a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
          sin(dLon / 2) * sin(dLon / 2);
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _deg2rad(double deg) => deg * pi / 180.0; 