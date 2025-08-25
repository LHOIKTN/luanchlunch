import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:launchlunch/data/hive/hive_helper.dart';
import 'package:launchlunch/data/supabase/api_service.dart';
import 'package:launchlunch/theme/app_colors.dart';
import 'package:launchlunch/utils/developer_mode.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SupabaseApi _api = SupabaseApi();
  bool _isDeveloperModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNickname();
    _loadDeveloperModeStatus();
  }

  void _loadNickname() {
    final nickname = HiveHelper.instance.getNickname();
    _nicknameController.text = nickname;
  }

  void _loadDeveloperModeStatus() async {
    final isEnabled = await DeveloperMode.isEnabled();
    setState(() {
      _isDeveloperModeEnabled = isEnabled;
    });
  }

  void _handleNicknameTap() async {
    // 닉네임이 "gattaca"가 아니면 조용히 아무 일도 하지 않음
    final isGattaca = await DeveloperMode.isGattacaNickname();
    if (!isGattaca) {
      return;
    }

    // 탭 처리
    final toggled = await DeveloperMode.handleNicknameTap();
    if (toggled) {
      // 개발자 모드 상태가 변경되었으면 UI 업데이트
      _loadDeveloperModeStatus();

      // 현재 개발자 모드 상태를 직접 확인하여 메시지 표시
      final isEnabled = await DeveloperMode.isEnabled();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEnabled ? '개발자 모드가 활성화되었습니다' : '개발자 모드가 비활성화되었습니다'),
            backgroundColor: isEnabled ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _saveNickname() async {
    final nickname = _nicknameController.text.trim();

    // 닉네임이 비어있으면 저장하지 않음
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('닉네임을 입력해주세요'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Hive에 저장
      await HiveHelper.instance.saveNickname(nickname);

      // Supabase에 업데이트 (닉네임이 있을 때만)
      final userUUID = HiveHelper.instance.getUserUUID();
      if (userUUID != null) {
        final result = await _api.updateNickname(userUUID, nickname);
        if (result['success'] == true) {
          print('✅ 닉네임 업데이트 완료: $nickname');
        } else {
          print('⚠️ Supabase 업데이트 실패: ${result['error']}');
        }
      } else {
        print('⚠️ 사용자 DB ID를 찾을 수 없음');
      }

      setState(() {
        // UI 업데이트를 위해 setState 호출
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('닉네임이 저장되었습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ 닉네임 저장 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('닉네임 저장에 실패했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 개발자 모드 상태 표시
              if (_isDeveloperModeEnabled)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.developer_mode, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        '개발자 모드 활성화됨',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              // 닉네임 설정 섹션
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                    GestureDetector(
                      onTap: _handleNicknameTap,
                      child: const Text(
                        '닉네임',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nicknameController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.text,
                      enableIMEPersonalizedLearning: true,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: '닉네임을 입력하세요',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveNickname,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '저장',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 개발자 모드 전용 앱 초기화 섹션
              if (_isDeveloperModeEnabled) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                          const Icon(Icons.build, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text(
                            '개발자 도구',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Android의 "앱 정보 → 저장소 및 캐시 → 모든 데이터 삭제"와 동일한 기능입니다.\n\n'
                        '• 모든 사용자 데이터 삭제\n'
                        '• 다운로드된 이미지 삭제\n'
                        '• 앱 자동 종료\n'
                        '• 다음 실행 시 초기 설치 상태로 시작',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 개발자 모드 해제 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _disableDeveloperMode,
                          icon: const Icon(Icons.toggle_off, size: 20),
                          label: const Text('개발자 모드 해제'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 모든 재료 획득 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _acquireAllIngredients,
                          icon: const Icon(Icons.inventory, size: 20),
                          label: const Text('모든 재료 획득'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 앱 초기화 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _resetApp,
                          icon: const Icon(Icons.restart_alt, size: 24),
                          label: const Text(
                            '앱 초기화 (Android 스타일)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '⚠️ 경고: 이 작업은 되돌릴 수 없습니다!\n앱이 자동으로 종료되며 모든 데이터가 삭제됩니다.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 하단 네비게이션을 위한 여백
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // 앱 완전 초기화 (Android 스타일)
  void _resetApp() async {
    final confirmed = await _showResetConfirmDialog();

    if (confirmed == true) {
      // 삭제 진행 상태를 보여주는 모달 다이얼로그 표시
      await _showDeletionProgressDialog();
    }
  }

  /// 삭제 진행 상태를 보여주는 모달 다이얼로그
  Future<void> _showDeletionProgressDialog() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // 다이얼로그 외부 탭으로 닫기 방지
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // 뒤로가기 버튼 차단
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 로딩 인디케이터
                  const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 제목
                  const Text(
                    '앱 초기화 중',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 경고 메시지
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning,
                                color: Colors.red, size: 24),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                '중요: 앱을 끄지 마세요!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• 모든 데이터를 삭제하고 있습니다\n'
                          '• 작업이 완료되면 자동으로 종료됩니다\n'
                          '• 중간에 앱을 끄면 데이터가 손상될 수 있습니다',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 진행 상태 텍스트
                  StreamBuilder<String>(
                    stream: _deletionProgressStream(),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? '삭제 준비 중...',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // 실제 삭제 작업 시작
    await _performDeletion();
  }

  /// 삭제 진행 상태 스트림
  Stream<String> _deletionProgressStream() async* {
    yield '삭제 준비 중...';
    await Future.delayed(const Duration(milliseconds: 800));

    yield 'Hive 데이터 삭제 중...';
    await Future.delayed(const Duration(milliseconds: 600));

    yield 'SharedPreferences 삭제 중...';
    await Future.delayed(const Duration(milliseconds: 400));

    yield '이미지 캐시 삭제 중...';
    await Future.delayed(const Duration(milliseconds: 600));

    yield '삭제 완료! 앱 종료 준비 중...';
  }

  /// 실제 삭제 작업 수행
  Future<void> _performDeletion() async {
    try {
      print('🔄 Android 스타일 앱 초기화 시작...');

      // 1단계: 사용자가 진행 상태를 볼 수 있도록 약간의 지연
      await Future.delayed(const Duration(milliseconds: 800));

      // 2단계: 모든 앱 데이터 삭제 (Android의 "모든 데이터 삭제"와 동일)
      // Hive 박스 + SharedPreferences + 이미지 캐시 모두 삭제
      print('📝 Step 1: 모든 데이터 삭제 시작 (Hive + SharedPreferences + 캐시)...');
      await HiveHelper.instance.clearAllAppData();
      print('✅ Step 1: 모든 데이터 삭제 완료');

      // 진행 상태 업데이트를 위한 지연
      await Future.delayed(const Duration(milliseconds: 1000));

      // 모든 삭제 작업 완료 확인
      print('✅ 모든 데이터 삭제 완료 - 앱 종료 준비');

      // 최종 메시지 표시를 위한 지연
      await Future.delayed(const Duration(milliseconds: 1000));

      print('🔚 앱 종료 시작...');

      // 안전한 앱 종료 (모든 삭제 작업이 완료된 후)
      if (Platform.isIOS) {
        // iOS에서는 SystemNavigator.pop()과 exit(0) 모두 사용
        SystemNavigator.pop();
        await Future.delayed(const Duration(milliseconds: 300));
        exit(0);
      } else {
        // Android에서는 SystemNavigator.pop() 사용
        SystemNavigator.pop();
      }
    } catch (e) {
      print('❌ 앱 초기화 실패: $e');

      // 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();

        // 에러 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('앱 초기화 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '확인',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }

  Future<bool> _showResetConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // 다이얼로그 외부 탭으로 닫기 방지
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Text('앱 완전 초기화'),
                ],
              ),
              content: const Text(
                'Android의 "앱 정보 → 저장소 및 캐시 → 모든 데이터 삭제"와 동일한 작업을 수행합니다.\n\n'
                '⚠️ 다음 작업이 실행됩니다:\n'
                '• 모든 사용자 데이터 삭제\n'
                '• 모든 획득 기록 삭제\n'
                '• 다운로드된 이미지 삭제\n'
                '• 앱 자동 종료\n\n'
                '이 작업은 되돌릴 수 없습니다.\n'
                '정말로 계속하시겠습니까?',
                style: TextStyle(height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    backgroundColor: Colors.red.withOpacity(0.1),
                  ),
                  child: const Text(
                    '초기화 실행',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // 개발자 모드 해제
  void _disableDeveloperMode() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('개발자 모드 해제'),
            ],
          ),
          content: const Text(
            '개발자 모드를 해제하면 모든 개발자 모드 기능이 비활성화됩니다.\n\n'
            '정말로 해제하시겠습니까?',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.red.withOpacity(0.1),
              ),
              child: const Text(
                '해제 실행',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await DeveloperMode.disable();
        _loadDeveloperModeStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('개발자 모드가 해제되었습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('❌ 개발자 모드 해제 실패: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('개발자 모드 해제에 실패했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // 모든 재료 획득 (개발자 모드 전용)
  void _acquireAllIngredients() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.inventory, color: Colors.green),
              SizedBox(width: 8),
              Text('모든 재료 획득'),
            ],
          ),
          content: const Text(
            '모든 음식 재료를 획득 상태로 변경합니다.\n\n'
            '이 작업은 개발 및 테스트 목적으로만 사용해주세요.\n'
            '계속하시겠습니까?',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                backgroundColor: Colors.green.withOpacity(0.1),
              ),
              child: const Text(
                '모든 재료 획득',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // 모든 음식 데이터 가져오기
        final allFoods = HiveHelper.instance.getAllFoods();
        final now = DateTime.now();
        int acquiredCount = 0;

        // 아직 획득하지 않은 재료들을 모두 획득 상태로 변경
        for (final food in allFoods) {
          if (food.acquiredAt == null) {
            await HiveHelper.instance.updateFoodAcquiredAt(food.id, now);
            acquiredCount++;
          }
        }

        // Supabase에도 동기화 시도
        final userUUID = HiveHelper.instance.getUserUUID();
        if (userUUID != null && acquiredCount > 0) {
          try {
            // 새로 획득한 재료들의 데이터 준비
            final newlyAcquiredItems = <Map<String, dynamic>>[];
            for (final food in allFoods) {
              if (food.acquiredAt != null &&
                  food.acquiredAt!
                      .isAfter(now.subtract(const Duration(seconds: 1)))) {
                newlyAcquiredItems.add({
                  'user_uuid': userUUID,
                  'food_id': food.id,
                  'acquired_at': now.toIso8601String(),
                });
              }
            }

            if (newlyAcquiredItems.isNotEmpty) {
              final api = SupabaseApi();
              await api.insertInventory(newlyAcquiredItems);
              print('✅ Supabase 동기화 완료: ${newlyAcquiredItems.length}개');
            }
          } catch (e) {
            print('⚠️ Supabase 동기화 실패: $e (로컬 저장은 완료됨)');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('모든 재료 획득 완료! (${acquiredCount}개 새로 획득)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('❌ 모든 재료 획득 실패: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('모든 재료 획득 실패: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
