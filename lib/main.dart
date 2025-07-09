import 'dart:async';
import 'dart:io' show Platform;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';

void main() {
  runApp(const LunchGameApp());
}

class GeolocatorApp extends StatelessWidget {
  const GeolocatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS 테스트 앱',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GeolocatorWidget(),
    );
  }
}

class LocationBookmark {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final DateTime timestamp;
  final String? description;

  LocationBookmark({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    required this.timestamp,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
    };
  }

  factory LocationBookmark.fromJson(Map<String, dynamic> json) {
    return LocationBookmark(
      id: json['id'],
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      altitude: json['altitude'],
      accuracy: json['accuracy'],
      timestamp: DateTime.parse(json['timestamp']),
      description: json['description'],
    );
  }
}

class GeolocatorWidget extends StatefulWidget {
  const GeolocatorWidget({super.key});

  @override
  State<GeolocatorWidget> createState() => _GeolocatorWidgetState();
}

class _GeolocatorWidgetState extends State<GeolocatorWidget> {
  static const String _kLocationServicesDisabledMessage =
      '위치 서비스가 비활성화되어 있습니다.';
  static const String _kPermissionDeniedMessage = '권한이 거부되었습니다.';
  static const String _kPermissionDeniedForeverMessage =
      '권한이 영구적으로 거부되었습니다.';
  static const String _kPermissionGrantedMessage = '권한이 허용되었습니다.';

  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  final List<_PositionItem> _positionItems = <_PositionItem>[];
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusStreamSubscription;
  bool positionStreamStarted = false;
  Position? _currentPosition;
  String _statusMessage = 'GPS 정보를 가져오는 중...';
  List<LocationBookmark> _bookmarks = [];
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _toggleServiceStatusStream();
    _checkPermissionAndGetLocation();
    _loadBookmarks();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _serviceStatusStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getStringList('location_bookmarks') ?? [];
    setState(() {
      _bookmarks = bookmarksJson
          .map((json) => LocationBookmark.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = _bookmarks
        .map((bookmark) => jsonEncode(bookmark.toJson()))
        .toList();
    await prefs.setStringList('location_bookmarks', bookmarksJson);
  }

  Future<void> _addBookmark() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 위치 정보가 없습니다.')),
      );
      return;
    }

    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('위치 북마크 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '북마크 이름',
                  hintText: '예: 집, 회사, 카페',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '설명 (선택사항)',
                  hintText: '추가 설명을 입력하세요',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop({
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                  });
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final bookmark = LocationBookmark(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['name']!,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        altitude: _currentPosition!.altitude,
        accuracy: _currentPosition!.accuracy,
        timestamp: DateTime.now(),
        description: result['description']!.isEmpty ? null : result['description'],
      );

      setState(() {
        _bookmarks.add(bookmark);
      });
      await _saveBookmarks();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${bookmark.name} 북마크가 저장되었습니다.')),
      );
    }
  }

  Future<void> _deleteBookmark(String id) async {
    final bookmark = _bookmarks.firstWhere((b) => b.id == id);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('북마크 삭제'),
          content: Text('${bookmark.name} 북마크를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _bookmarks.removeWhere((b) => b.id == id);
      });
      await _saveBookmarks();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${bookmark.name} 북마크가 삭제되었습니다.')),
      );
    }
  }

  Future<void> _checkPermissionAndGetLocation() async {
    if (await _handlePermission()) {
      await _getCurrentPosition();
    }
  }

  PopupMenuButton _createActions() {
    return PopupMenuButton(
      elevation: 40,
      onSelected: (value) async {
        switch (value) {
          case 1:
            _getLocationAccuracy();
            break;
          case 2:
            _requestTemporaryFullAccuracy();
            break;
          case 3:
            _openAppSettings();
            break;
          case 4:
            _openLocationSettings();
            break;
          case 5:
            setState(() {
              _positionItems.clear();
              _currentPosition = null;
            });
            break;
        }
      },
      itemBuilder: (context) => [
        if (Platform.isIOS)
          const PopupMenuItem(value: 1, child: Text("위치 정확도 확인")),
        if (Platform.isIOS)
          const PopupMenuItem(value: 2, child: Text("정확한 위치 요청")),
        const PopupMenuItem(value: 3, child: Text("앱 설정 열기")),
        if (Platform.isAndroid || Platform.isWindows)
          const PopupMenuItem(value: 4, child: Text("위치 설정 열기")),
        const PopupMenuItem(value: 5, child: Text("초기화")),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("GPS 테스트 앱"),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [_createActions()],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.my_location), text: '현재 위치'),
              Tab(icon: Icon(Icons.bookmark), text: '북마크'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCurrentLocationTab(),
            _buildBookmarksTab(),
          ],
        ),
        floatingActionButton: _currentTabIndex == 0 ? _buildLocationButtons() : _buildBookmarkButton(),
      ),
    );
  }

  Widget _buildCurrentLocationTab() {
    return Column(
      children: [
        // GPS Status Card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _currentPosition != null ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _currentPosition != null ? Colors.green : Colors.orange,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _currentPosition != null ? Icons.location_on : Icons.location_off,
                    color: _currentPosition != null ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentPosition != null ? 'GPS 연결됨' : 'GPS 연결 중...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _currentPosition != null ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        
        // GPS Information Cards
        if (_currentPosition != null) ...[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildInfoCard(
                    '위치 좌표',
                    Icons.my_location,
                    [
                      _buildInfoRow('위도', '${_currentPosition!.latitude.toStringAsFixed(6)}°'),
                      _buildInfoRow('경도', '${_currentPosition!.longitude.toStringAsFixed(6)}°'),
                      _buildInfoRow('고도', '${_currentPosition!.altitude.toStringAsFixed(1)}m'),
                    ],
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    '정확도',
                    Icons.gps_fixed,
                    [
                      _buildInfoRow('수평 정확도', '${_currentPosition!.accuracy.toStringAsFixed(1)}m'),
                      _buildInfoRow('방향 정확도', '${_currentPosition!.headingAccuracy.toStringAsFixed(1)}°'),
                    ],
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    '속도 정보',
                    Icons.speed,
                    [
                      _buildInfoRow('속도', '${_currentPosition!.speed.toStringAsFixed(1)}m/s'),
                      _buildInfoRow('방향', '${_currentPosition!.heading.toStringAsFixed(1)}°'),
                      _buildInfoRow('속도 정확도', '${_currentPosition!.speedAccuracy.toStringAsFixed(1)}m/s'),
                    ],
                    Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    '시간 정보',
                    Icons.access_time,
                    [
                      _buildInfoRow('타임스탬프', _currentPosition!.timestamp.toString()),
                    ],
                    Colors.purple,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ] else ...[
          // Loading or Error State
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_searching,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'GPS 정보를 가져오는 중...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '위치 권한을 허용해주세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBookmarksTab() {
    return _bookmarks.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  '저장된 북마크가 없습니다',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '현재 위치 탭에서 북마크를 추가해보세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = _bookmarks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.location_on, color: Colors.blue.shade700),
                  ),
                  title: Text(
                    bookmark.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '위도: ${bookmark.latitude.toStringAsFixed(6)}°, 경도: ${bookmark.longitude.toStringAsFixed(6)}°',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      if (bookmark.description != null)
                        Text(
                          bookmark.description!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      Text(
                        '저장: ${_formatDateTime(bookmark.timestamp)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteBookmark(bookmark.id),
                  ),
                  onTap: () {
                    // 북마크 위치 정보를 상세히 보여주는 다이얼로그
                    _showBookmarkDetails(bookmark);
                  },
                ),
              );
            },
          );
  }

  void _showBookmarkDetails(LocationBookmark bookmark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(bookmark.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('위도', '${bookmark.latitude.toStringAsFixed(6)}°'),
              _buildInfoRow('경도', '${bookmark.longitude.toStringAsFixed(6)}°'),
              if (bookmark.altitude != null)
                _buildInfoRow('고도', '${bookmark.altitude!.toStringAsFixed(1)}m'),
              if (bookmark.accuracy != null)
                _buildInfoRow('정확도', '${bookmark.accuracy!.toStringAsFixed(1)}m'),
              _buildInfoRow('저장 시간', _formatDateTime(bookmark.timestamp)),
              if (bookmark.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  '설명:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
                Text(bookmark.description!),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLocationButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          onPressed: () {
            positionStreamStarted = !positionStreamStarted;
            _toggleListening();
          },
          tooltip: _positionStreamSubscription == null
              ? '실시간 위치 업데이트 시작'
              : _positionStreamSubscription!.isPaused
                  ? '재개'
                  : '일시정지',
          backgroundColor: _isListening() ? Colors.green : Colors.red,
          icon: _isListening()
              ? const Icon(Icons.pause)
              : const Icon(Icons.play_arrow),
          label: Text(_isListening() ? '일시정지' : '실시간'),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          onPressed: _getCurrentPosition,
          icon: const Icon(Icons.my_location),
          label: const Text('현재 위치'),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.extended(
          onPressed: _getLastKnownPosition,
          icon: const Icon(Icons.bookmark),
          label: const Text('마지막 위치'),
        ),
      ],
    );
  }

  Widget _buildBookmarkButton() {
    return FloatingActionButton.extended(
      onPressed: _addBookmark,
      icon: const Icon(Icons.add),
      label: const Text('북마크 추가'),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  bool _isListening() =>
      _positionStreamSubscription != null &&
      !_positionStreamSubscription!.isPaused;

  void _toggleServiceStatusStream() {
    if (_serviceStatusStreamSubscription == null) {
      _serviceStatusStreamSubscription =
          _geolocatorPlatform.getServiceStatusStream().listen((status) {
        String message;
        if (status == ServiceStatus.enabled) {
          if (positionStreamStarted) _toggleListening();
          message = '위치 서비스가 활성화되었습니다';
        } else {
          _positionStreamSubscription?.cancel();
          _positionStreamSubscription = null;
          message = '위치 서비스가 비활성화되었습니다';
        }
        setState(() {
          _statusMessage = message;
        });
        _updatePositionList(_PositionItemType.log, message);
      }, onError: (_) {
        _serviceStatusStreamSubscription?.cancel();
        _serviceStatusStreamSubscription = null;
      });
    }
  }

  void _toggleListening() {
    if (_positionStreamSubscription == null) {
      _positionStreamSubscription =
          _geolocatorPlatform.getPositionStream().listen((position) {
        setState(() {
          _currentPosition = position;
          _statusMessage = '실시간 위치 업데이트 중...';
        });
        _updatePositionList(
            _PositionItemType.position, position.toString());
      }, onError: (_) {
        _positionStreamSubscription?.cancel();
        _positionStreamSubscription = null;
      });
      _positionStreamSubscription?.pause();
    }

    setState(() {
      if (_positionStreamSubscription == null) return;

      if (_positionStreamSubscription!.isPaused) {
        _positionStreamSubscription!.resume();
        _statusMessage = '실시간 위치 업데이트 재개됨';
        _updatePositionList(_PositionItemType.log, '위치 업데이트 재개됨');
      } else {
        _positionStreamSubscription!.pause();
        _statusMessage = '실시간 위치 업데이트 일시정지됨';
        _updatePositionList(_PositionItemType.log, '위치 업데이트 일시정지됨');
      }
    });
  }

  Future<void> _getCurrentPosition() async {
    if (await _handlePermission()) {
      try {
        final position = await _geolocatorPlatform.getCurrentPosition();
        setState(() {
          _currentPosition = position;
          _statusMessage = '현재 위치를 성공적으로 가져왔습니다';
        });
        _updatePositionList(
            _PositionItemType.position, position.toString());
      } catch (e) {
        setState(() {
          _statusMessage = '위치를 가져오는 중 오류가 발생했습니다: $e';
        });
      }
    }
  }

  Future<void> _getLastKnownPosition() async {
    try {
      final position = await _geolocatorPlatform.getLastKnownPosition();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _statusMessage = '마지막 알려진 위치를 가져왔습니다';
        });
        _updatePositionList(
            _PositionItemType.position, position.toString());
      } else {
        setState(() {
          _statusMessage = '마지막 알려진 위치가 없습니다';
        });
        _updatePositionList(
            _PositionItemType.log, '마지막 알려진 위치가 없습니다');
      }
    } catch (e) {
      setState(() {
        _statusMessage = '마지막 위치를 가져오는 중 오류가 발생했습니다: $e';
      });
    }
  }

  Future<bool> _handlePermission() async {
    try {
      // 위치 서비스가 활성화되어 있는지 확인
      bool serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _statusMessage = '위치 서비스가 비활성화되어 있습니다. 설정에서 위치 서비스를 활성화해주세요.';
        });
        _updatePositionList(
            _PositionItemType.log, _kLocationServicesDisabledMessage);
        
        // 위치 설정을 열어주는 옵션 제공
        _showLocationServiceDialog();
        return false;
      }

      // 현재 권한 상태 확인
      LocationPermission permission = await _geolocatorPlatform.checkPermission();
      
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = '위치 권한을 요청합니다...';
        });
        
        // 권한 요청
        permission = await _geolocatorPlatform.requestPermission();
        
        if (permission == LocationPermission.denied) {
          setState(() {
            _statusMessage = '위치 권한이 거부되었습니다. 앱 설정에서 권한을 허용해주세요.';
          });
          _updatePositionList(
              _PositionItemType.log, _kPermissionDeniedMessage);
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _statusMessage = '위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용해주세요.';
        });
        _updatePositionList(
            _PositionItemType.log, _kPermissionDeniedForeverMessage);
        
        // 앱 설정을 열어주는 옵션 제공
        _showPermissionSettingsDialog();
        return false;
      }

      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        setState(() {
          _statusMessage = '위치 권한이 허용되었습니다. GPS 정보를 가져오는 중...';
        });
        _updatePositionList(
            _PositionItemType.log, _kPermissionGrantedMessage);
        return true;
      }

      return false;
    } catch (e) {
      setState(() {
        _statusMessage = '권한 확인 중 오류가 발생했습니다: $e';
      });
      return false;
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('위치 서비스 비활성화'),
          content: const Text('GPS 기능을 사용하려면 위치 서비스를 활성화해야 합니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openLocationSettings();
              },
              child: const Text('설정 열기'),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('위치 권한 필요'),
          content: const Text('GPS 기능을 사용하려면 위치 권한이 필요합니다. 앱 설정에서 권한을 허용해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openAppSettings();
              },
              child: const Text('앱 설정 열기'),
            ),
          ],
        );
      },
    );
  }

  void _getLocationAccuracy() async {
    final status = await _geolocatorPlatform.getLocationAccuracy();
    _handleLocationAccuracyStatus(status);
  }

  void _requestTemporaryFullAccuracy() async {
    final status = await _geolocatorPlatform
        .requestTemporaryFullAccuracy(purposeKey: "TemporaryPreciseAccuracy");
    _handleLocationAccuracyStatus(status);
  }

  void _handleLocationAccuracyStatus(LocationAccuracyStatus status) {
    final value = status == LocationAccuracyStatus.precise
        ? '정확한'
        : status == LocationAccuracyStatus.reduced
            ? '제한된'
            : '알 수 없는';

    setState(() {
      _statusMessage = '$value 위치 정확도가 허용되었습니다.';
    });
    _updatePositionList(
        _PositionItemType.log, '$value 위치 정확도가 허용되었습니다.');
  }

  void _openAppSettings() async {
    final opened = await _geolocatorPlatform.openAppSettings();
    _updatePositionList(
        _PositionItemType.log,
        opened
            ? '앱 설정이 열렸습니다.'
            : '앱 설정을 여는 중 오류가 발생했습니다.');
  }

  void _openLocationSettings() async {
    final opened = await _geolocatorPlatform.openLocationSettings();
    _updatePositionList(
        _PositionItemType.log,
        opened
            ? '위치 설정이 열렸습니다'
            : '위치 설정을 여는 중 오류가 발생했습니다');
  }

  void _updatePositionList(_PositionItemType type, String displayValue) {
    setState(() {
      _positionItems.add(_PositionItem(type, displayValue));
    });
  }
}

enum _PositionItemType { log, position }

class _PositionItem {
  _PositionItem(this.type, this.displayValue);
  final _PositionItemType type;
  final String displayValue;
}
