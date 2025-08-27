import 'package:flutter/material.dart';
import 'package:launchlunch/features/game_start/screen.dart';
import 'package:launchlunch/utils/preload.dart';
import 'package:launchlunch/utils/image_validator.dart';
import 'package:launchlunch/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _startAnimations();
    _startPreload(); // 애니메이션과 동시에 로딩 시작
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _scaleController.forward();
  }

  void _startPreload() async {
    print('🔄 스플래시 화면에서 데이터 프리로드 시작...');

    setState(() {
      _isLoading = true;
    });

    try {
      print('📦 PreloadData 인스턴스 생성...');
      final preloader = PreloadData();

      print('🚀 preloadAllData() 호출 시작...');
      await preloader.preloadAllData();
      print('✅ preloadAllData() 완료!');

      // 이미지 유효성 검사 및 복구
      print('🔍 이미지 유효성 검사 시작...');
      final imageValidator = ImageValidator();
      await imageValidator.validateAndRepairImages();
      print('✅ 이미지 유효성 검사 완료!');

      // 프리로드 완료 후 게임 시작 화면으로 이동
      if (mounted) {
        print('🎮 GameStartScreen으로 이동...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GameStartScreen()),
        );
      } else {
        print('⚠️ 위젯이 마운트되지 않음 - 화면 이동 취소');
      }
    } catch (e) {
      print('❌ 프리로드 실패: $e');
      print('❌ 에러 상세: ${e.toString()}');
      print('❌ 스택 트레이스: ${StackTrace.current}');

      // 에러가 발생해도 게임 시작 화면으로 이동 (오프라인 모드)
      if (mounted) {
        print('🔄 오프라인 모드로 GameStartScreen 이동...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GameStartScreen()),
        );
      } else {
        print('⚠️ 위젯이 마운트되지 않음 - 오프라인 모드 이동도 취소');
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 애니메이션
            AnimatedBuilder(
              animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // 앱 이름
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: const Text(
                    '한입두입',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontFamily: 'HakgyoansimDunggeunmiso',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 로딩 인디케이터
            if (_isLoading)
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: const Column(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '데이터를 불러오는 중...',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textHint,
                            fontFamily: 'HakgyoansimDunggeunmiso',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
