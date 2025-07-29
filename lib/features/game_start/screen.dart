import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../home/screen.dart';
import 'dart:math';
import 'dart:ui' as ui;

class GameStartScreen extends StatefulWidget {
  const GameStartScreen({super.key});

  @override
  State<GameStartScreen> createState() => _GameStartScreenState();
}

class _GameStartScreenState extends State<GameStartScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _buttonController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _particleAnimation;

  // 모든 음식 이미지 리스트 (assets/images 폴더의 모든 webp 파일)
  final List<String> foodImages = [
    'assets/images/6soo.webp',
    'assets/images/apple.webp',
    'assets/images/banana.webp',
    'assets/images/bean_sprout.webp',
    'assets/images/beef_seaweed_soup.webp',
    'assets/images/beef.webp',
    'assets/images/blueberry_rice_ball.webp',
    'assets/images/blueberry_rice.webp',
    'assets/images/blueberry.webp',
    'assets/images/bread.webp',
    'assets/images/buckwheat_noodles.webp',
    'assets/images/buckwheat.webp',
    'assets/images/butter.webp',
    'assets/images/cabbage.webp',
    'assets/images/cake.webp',
    'assets/images/carrot.webp',
    'assets/images/cheese.webp',
    'assets/images/chicken.webp',
    'assets/images/corn.webp',
    'assets/images/cow.webp',
    'assets/images/cucumber.webp',
    'assets/images/curry_powder.webp',
    'assets/images/curry_rice.webp',
    'assets/images/curry.webp',
    'assets/images/cutlet_cheese.webp',
    'assets/images/cutlet_fish.webp',
    'assets/images/cutlet.webp',
    'assets/images/doenjang.webp',
    'assets/images/dressing.webp',
    'assets/images/dried_laver.webp',
    'assets/images/egg.webp',
    'assets/images/eggplant_moochym.webp',
    'assets/images/eggplant.webp',
    'assets/images/extract_lemon.webp',
    'assets/images/fish_block.webp',
    'assets/images/fish.webp',
    'assets/images/fork.webp',
    'assets/images/garlic.webp',
    'assets/images/ginseng.webp',
    'assets/images/gochu_oil.webp',
    'assets/images/gochu.webp',
    'assets/images/gochugaru.webp',
    'assets/images/gochujang.webp',
    'assets/images/green_onion.webp',
    'assets/images/je6bokkeum.webp',
    'assets/images/kong_rice.webp',
    'assets/images/lemon.webp',
    'assets/images/lettuce.webp',
    'assets/images/mandoo.webp',
    'assets/images/mara.webp',
    'assets/images/mayo_spam.webp',
    'assets/images/mayonnaise.webp',
    'assets/images/meju.webp',
    'assets/images/milk.webp',
    'assets/images/misosoup_muchroom.webp',
    'assets/images/misosoup.webp',
    'assets/images/mushroom.webp',
    'assets/images/napa_cabbage.webp',
    'assets/images/noodle.webp',
    'assets/images/octopus.webp',
    'assets/images/oil.webp',
    'assets/images/olive_oil.webp',
    'assets/images/orange.webp',
    'assets/images/pajeon_haemool.webp',
    'assets/images/pajeon.webp',
    'assets/images/pig.webp',
    'assets/images/pineapple.webp',
    'assets/images/ponytail_radish.webp',
    'assets/images/potato.webp',
    'assets/images/radish.webp',
    'assets/images/red_tang.webp',
    'assets/images/rice_ball.webp',
    'assets/images/rice.webp',
    'assets/images/rice2.webp',
    'assets/images/salad_apple.webp',
    'assets/images/salad_tomato.webp',
    'assets/images/salad.webp',
    'assets/images/salt.webp',
    'assets/images/sancho.webp',
    'assets/images/seaweed_soup.webp',
    'assets/images/seaweed.webp',
    'assets/images/sesame_oil.webp',
    'assets/images/sesame.webp',
    'assets/images/shrimp.webp',
    'assets/images/soy_sauce.webp',
    'assets/images/soybean.webp',
    'assets/images/spinach_moochym.webp',
    'assets/images/spinach.webp',
    'assets/images/squid.webp',
    'assets/images/steamed_egg.webp',
    'assets/images/sugar.webp',
    'assets/images/takoyakii.webp',
    'assets/images/tofu.webp',
    'assets/images/tomato_sauce.webp',
    'assets/images/tomato_spaghetti.webp',
    'assets/images/tomato.webp',
    'assets/images/vinegar.webp',
    'assets/images/watermelon.webp',
    'assets/images/wheat_flour.webp',
    'assets/images/wheat.webp',
  ];

  // 파티클 리스트
  List<FoodParticle> particles = [];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 60), // 더 긴 지속시간
      vsync: this,
    )..repeat(); // 무한 반복

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeOutBack,
    ));

    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.linear,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _buttonController.forward();

    // _particleController는 이미 repeat()로 시작됨
  }

  void _onPlayButtonPressed() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  bool _isTablet(BuildContext context) {
    final data = MediaQuery.of(context);
    final shortestSide = data.size.shortestSide;
    final longestSide = data.size.longestSide;

    // 더 정확한 태블릿 판별: 최소 크기가 600dp 이상이거나 큰 화면 비율
    final isLargeScreen = shortestSide >= 600;
    final hasTabletRatio = longestSide / shortestSide < 2.0; // 너무 길쭉하지 않은 화면

    print(
        '📱 화면 크기: ${data.size.width.toInt()}x${data.size.height.toInt()}, 최소: ${shortestSide.toInt()}dp');
    print('📱 디바이스 판별: ${isLargeScreen ? "태블릿" : "모바일"} (최소크기 >= 600dp)');

    return isLargeScreen && hasTabletRatio;
  }

  void _initializeParticles(double width, double height, BuildContext context) {
    if (particles.isNotEmpty) return;

    final random = Random();
    particles.clear();

    // 디바이스 타입에 따른 파티클 수 결정
    final isTablet = _isTablet(context);
    final targetParticleCount = isTablet ? 32 : 16;

    print('🎯 목표 파티클 수: $targetParticleCount개 (${isTablet ? "태블릿" : "모바일"})');

    // 사용할 이미지 랜덤 선택 (중복 방지)
    final shuffledImages = List<String>.from(foodImages)..shuffle(random);
    final selectedImages = shuffledImages.take(targetParticleCount).toList();

    // 파티클을 겹치지 않게 생성
    int attempts = 0;
    int imageIndex = 0;
    while (particles.length < targetParticleCount && attempts < 2000) {
      attempts++;

      final size = isTablet ? 120.0 : 80.0; // 태블릿일 때 1.5배 크기
      final x = size + random.nextDouble() * (width - 2 * size);
      final y = size + random.nextDouble() * (height - 2 * size);

      // 다른 파티클과 겹치는지 확인
      bool overlaps = false;
      for (final existing in particles) {
        final distance = sqrt(pow(x - existing.x, 2) + pow(y - existing.y, 2));
        if (distance < (size + existing.size) / 2 + 10) {
          // 여유 공간 추가
          overlaps = true;
          break;
        }
      }

      if (!overlaps) {
        particles.add(FoodParticle(
          x: x,
          y: y,
          vx: (random.nextDouble() - 0.5) * 150, // 속도 줄임
          vy: (random.nextDouble() - 0.5) * 150,
          size: size,
          imagePath: selectedImages[imageIndex],
        ));
        imageIndex++;
      }
    }

    print('🎮 파티클 생성 완료: ${particles.length}개 (${isTablet ? "태블릿" : "모바일"})');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _buttonController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    _initializeParticles(screenWidth, screenHeight, context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0E6FF), // 연한 보라색 (더 진하게)
      body: Stack(
        children: [
          // 이미지 파티클들
          AnimatedBuilder(
            animation: _particleAnimation,
            builder: (context, child) {
              // 파티클 업데이트
              final dt = 0.016;
              for (final particle in particles) {
                particle.update(dt, screenWidth, screenHeight);
              }

              // 충돌 검사
              for (int i = 0; i < particles.length; i++) {
                for (int j = i + 1; j < particles.length; j++) {
                  if (particles[i].collidesWith(particles[j])) {
                    particles[i].collideWith(particles[j]);
                  }
                }
              }

              return SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: Stack(
                  children: particles.map((particle) {
                    return Positioned(
                      left: particle.x - particle.size / 2,
                      top: particle.y - particle.size / 2,
                      child: Container(
                        width: particle.size,
                        height: particle.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.9),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.8),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.asset(
                            particle.imagePath,
                            width: particle.size - 8,
                            height: particle.size - 8,
                            fit: BoxFit.contain, // 이미지 전체가 보이도록 변경
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: particle.size - 8,
                                height: particle.size - 8,
                                color: AppColors.primary.withOpacity(0.3),
                                child: Icon(
                                  Icons.fastfood,
                                  size: particle.size * 0.4,
                                  color: AppColors.primary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          // 플레이 버튼
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.1,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _buttonAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _buttonAnimation.value.clamp(0.0, 1.0),
                  child: Opacity(
                    opacity: _buttonAnimation.value.clamp(0.0, 1.0),
                    child: Center(
                      child: GestureDetector(
                        onTap: _onPlayButtonPressed,
                        child: Container(
                          width: 250,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '플레이',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 게임 제목
          Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                  child: const Center(
                    child: Text(
                      '한입두입',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FoodParticle {
  double x, y;
  double vx, vy;
  double size;
  String imagePath;

  FoodParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.imagePath,
  });

  void update(double dt, double width, double height) {
    x += vx * dt;
    y += vy * dt;

    // 벽에 부딪히면 튕겨나가기 (반지름 고려)
    final radius = size / 2;
    if (x - radius <= 0 || x + radius >= width) {
      vx = -vx; // 에너지 손실 없이 완전 탄성 충돌
      x = x - radius <= 0 ? radius : width - radius;
    }
    if (y - radius <= 0 || y + radius >= height) {
      vy = -vy; // 에너지 손실 없이 완전 탄성 충돌
      y = y - radius <= 0 ? radius : height - radius;
    }
  }

  bool collidesWith(FoodParticle other) {
    final distance = sqrt(pow(x - other.x, 2) + pow(y - other.y, 2));
    return distance < (size + other.size) / 2;
  }

  void collideWith(FoodParticle other) {
    // 충돌 시 실제 물리학적 반응
    final dx = other.x - x;
    final dy = other.y - y;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance == 0) return; // 동일한 위치 방지

    // 정규화된 충돌 벡터
    final nx = dx / distance;
    final ny = dy / distance;

    // 상대 속도
    final dvx = other.vx - vx;
    final dvy = other.vy - vy;

    // 충돌 방향으로의 상대 속도
    final dvn = dvx * nx + dvy * ny;

    // 이미 분리되고 있으면 충돌 처리 안함
    if (dvn > 0) return;

    // 반발력 (탄성 충돌)
    final impulse = 2 * dvn / 2; // 질량이 같다고 가정

    vx += impulse * nx;
    vy += impulse * ny;
    other.vx -= impulse * nx;
    other.vy -= impulse * ny;

    // 파티클 분리 (겹침 방지)
    final overlap = (size + other.size) / 2 - distance;
    if (overlap > 0) {
      final separationX = nx * overlap / 2;
      final separationY = ny * overlap / 2;
      x -= separationX;
      y -= separationY;
      other.x += separationX;
      other.y += separationY;
    }

    // 속도 제한을 높여서 더 역동적인 움직임 허용
    final maxSpeed = 400; // 기존 200에서 400으로 증가
    final speed = sqrt(vx * vx + vy * vy);
    if (speed > maxSpeed) {
      vx = (vx / speed) * maxSpeed;
      vy = (vy / speed) * maxSpeed;
    }

    final otherSpeed = sqrt(other.vx * other.vx + other.vy * other.vy);
    if (otherSpeed > maxSpeed) {
      other.vx = (other.vx / otherSpeed) * maxSpeed;
      other.vy = (other.vy / otherSpeed) * maxSpeed;
    }
  }
}
