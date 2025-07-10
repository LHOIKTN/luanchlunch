import 'package:flutter/material.dart';
import '../../core/utils.dart';

class LocationCheckScreen extends StatefulWidget {
  const LocationCheckScreen({super.key});

  @override
  State<LocationCheckScreen> createState() => _LocationCheckScreenState();
}

class _LocationCheckScreenState extends State<LocationCheckScreen> {
  // 샘플 급식실 위치 (실제 데이터로 교체 필요)
  static const double cafeteriaLat = 37.5665; // 서울시청 위도
  static const double cafeteriaLon = 126.9780; // 서울시청 경도
  static const double cafeteriaRadius = 20.0; // 급식실 반경 20m

  // 급식 시간 (11:30 ~ 13:00)
  static const int lunchStartHour = 11;
  static const int lunchStartMinute = 30;
  static const int lunchEndHour = 13;
  static const int lunchEndMinute = 0;

  // 샘플 사용자 위치 (테스트용)
  double userLat = 37.5665; // 서울시청 근처
  double userLon = 126.9780;
  DateTime currentTime = DateTime.now();

  bool isInCafeteria = false;
  bool isLunchTime = false;
  bool canGetIngredient = false;

  @override
  void initState() {
    super.initState();
    _checkConditions();
  }

  void _checkConditions() {
    // 위치 조건 확인
    final distance = calculateDistance(
      cafeteriaLat, cafeteriaLon, userLat, userLon
    );
    isInCafeteria = distance <= cafeteriaRadius;

    // 시간 조건 확인
    final now = DateTime.now();
    final lunchStart = DateTime(now.year, now.month, now.day, lunchStartHour, lunchStartMinute);
    final lunchEnd = DateTime(now.year, now.month, now.day, lunchEndHour, lunchEndMinute);
    isLunchTime = now.isAfter(lunchStart) && now.isBefore(lunchEnd);

    // 두 조건 모두 만족 시 재료 획득 가능
    canGetIngredient = isInCafeteria && isLunchTime;

    setState(() {});
  }

  void _updateLocation(double lat, double lon) {
    setState(() {
      userLat = lat;
      userLon = lon;
      _checkConditions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('급식실 & 시간 확인'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            _buildLocationInfo(),
            const SizedBox(height: 24),
            _buildTimeInfo(),
            const SizedBox(height: 24),
            _buildTestButtons(),
            const Spacer(),
            _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: canGetIngredient ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              canGetIngredient ? Icons.check_circle : Icons.cancel,
              size: 48,
              color: canGetIngredient ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 8),
            Text(
              canGetIngredient ? '재료 획득 가능!' : '재료 획득 불가',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: canGetIngredient ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    final distance = calculateDistance(cafeteriaLat, cafeteriaLon, userLat, userLon);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isInCafeteria ? Icons.location_on : Icons.location_off,
                  color: isInCafeteria ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  '위치 조건',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isInCafeteria ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('급식실까지 거리: ${distance.toStringAsFixed(1)}m'),
            Text('조건: ${cafeteriaRadius}m 이내'),
            Text('상태: ${isInCafeteria ? "충족" : "미충족"}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isLunchTime ? Icons.access_time : Icons.schedule,
                  color: isLunchTime ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  '시간 조건',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isLunchTime ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('현재 시간: ${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}'),
            Text('급식 시간: ${lunchStartHour.toString().padLeft(2, '0')}:${lunchStartMinute.toString().padLeft(2, '0')} ~ ${lunchEndHour.toString().padLeft(2, '0')}:${lunchEndMinute.toString().padLeft(2, '0')}'),
            Text('상태: ${isLunchTime ? "충족" : "미충족"}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '테스트 위치 변경',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateLocation(37.5665, 126.9780), // 급식실 근처
                child: const Text('급식실 근처'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateLocation(37.5700, 126.9800), // 멀리
                child: const Text('멀리'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _checkConditions,
          child: const Text('조건 다시 확인'),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '조건 요약',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('위치 조건: ${isInCafeteria ? "✅" : "❌"}'),
            Text('시간 조건: ${isLunchTime ? "✅" : "❌"}'),
            const SizedBox(height: 8),
            Text(
              canGetIngredient ? '재료 획득 가능합니다!' : '재료 획득 조건을 확인하세요.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: canGetIngredient ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 