import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 샘플에 필요한 파일(assets 폴더에 직접 넣으세요):
/// - assets/egg.jpg (재료1)
/// - assets/rice.jpg (재료2)
/// - assets/kimbap.jpg (완성 요리)
/// - assets/cooking.json (Lottie 파티클 효과)

class CombineAnimation extends StatefulWidget {
  final VoidCallback? onComplete;
  const CombineAnimation({super.key, this.onComplete});

  @override
  State<CombineAnimation> createState() => _CombineAnimationState();
}

class _CombineAnimationState extends State<CombineAnimation>
    with TickerProviderStateMixin {
  bool _isCombining = false;
  bool _showParticles = false;
  bool _showResult = false;

  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(vsync: this);
    _startAnimation();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() => _isCombining = true);
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() => _showParticles = true);
    _particleController.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() => _showResult = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. 재료 아이콘(AnimatedAlign)
          AnimatedAlign(
            alignment: _isCombining ? Alignment.center : const Alignment(-1.2, 0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            child: Image.asset('assets/egg.jpg', width: 56),
          ),
          AnimatedAlign(
            alignment: _isCombining ? Alignment.center : const Alignment(1.2, 0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            child: Image.asset('assets/rice.jpg', width: 56),
          ),
          // 2. 파티클 효과 (Lottie)
          if (_showParticles)
            Lottie.asset('assets/cooking.json',
              width: 160,
              controller: _particleController,
              onLoaded: (composition) {
                _particleController.duration = composition.duration;
                _particleController.forward();
              },
            ),
          // 3. 요리 완성 이미지
          if (_showResult)
            AnimatedScale(
              scale: _showResult ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Image.asset('assets/kimbap.jpg', width: 90),
            ),
          // 4. 성공 텍스트
          if (_showResult)
            Positioned(
              bottom: 24,
              child: AnimatedOpacity(
                opacity: _showResult ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Text(
                  '성공!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black26,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 