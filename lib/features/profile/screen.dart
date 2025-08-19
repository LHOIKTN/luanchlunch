import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:launchlunch/data/hive/hive_helper.dart';
import 'package:launchlunch/data/supabase/api_service.dart';
import 'package:launchlunch/theme/app_colors.dart';
import 'package:launchlunch/utils/developer_mode.dart';

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
        child: Padding(
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
            ],
          ),
        ),
      ),
    );
  }
}
