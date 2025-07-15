import 'package:flutter/material.dart';
import 'package:launchlunch/models/food.dart';
import 'package:launchlunch/data/hive/hive_helper.dart';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:io'; // File 클래스를 사용하기 위해 추가

// --- 커스텀 위젯/클래스 최상단 선언 ---
class FoodDetailModal extends StatelessWidget {
  final Food food;
  final void Function(Food) onIngredientTap;
  final VoidCallback onClose;
  final List<Food> allFoods; // 모든 음식 목록을 전달받음
  
  const FoodDetailModal({
    required this.food,
    required this.onIngredientTap,
    required this.onClose,
    required this.allFoods,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final recipeFoods = food.recipes?.map((id) => allFoods.firstWhere((f) => f.id == id)).toList() ?? [];
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  food.imageUrl.startsWith('assets/') 
                    ? Image.asset(food.imageUrl, width: 80, height: 80, fit: BoxFit.contain)
                    : Image.file(File(food.imageUrl), width: 80, height: 80, fit: BoxFit.contain),
                  const SizedBox(height: 16),
                  Text(food.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text('${food.name}에 대한 설명입니다. 다양한 요리에 활용할 수 있는 재료입니다.', style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
                  if (recipeFoods.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('레시피', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: recipeFoods.map((f) => GestureDetector(
                        onTap: () => onIngredientTap(f),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              f.imageUrl.startsWith('assets/') 
                                ? Image.asset(f.imageUrl, width: 40, height: 40)
                                : Image.file(File(f.imageUrl), width: 40, height: 40),
                              const SizedBox(height: 4),
                              Text(f.name, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextButton(onPressed: onClose, child: const Text('닫기')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 대표 색상 추출 함수
Future<Color> getDominantColor(String imagePath) async {
  ImageProvider imageProvider;
  if (imagePath.startsWith('assets/')) {
    imageProvider = AssetImage(imagePath);
  } else {
    imageProvider = FileImage(File(imagePath));
  }
  final palette = await PaletteGenerator.fromImageProvider(imageProvider);
  return palette.dominantColor?.color ?? Colors.blue.shade100;
}

// CompleteOverlay를 StatefulWidget으로 변경
class CompleteOverlay extends StatefulWidget {
  final Food food;
  final VoidCallback onClose;
  final VoidCallback onLongPress;
  const CompleteOverlay({
    required this.food,
    required this.onClose,
    required this.onLongPress,
    Key? key,
  }) : super(key: key);

  @override
  State<CompleteOverlay> createState() => _CompleteOverlayState();
}

class _CompleteOverlayState extends State<CompleteOverlay> {
  Color raysColor = Colors.blue.shade100;

  @override
  void initState() {
    super.initState();
    _updateDominantColor();
  }

  Future<void> _updateDominantColor() async {
    final color = await getDominantColor(widget.food.imageUrl);
    setState(() {
      raysColor = color.withOpacity(0.3);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      onLongPress: widget.onLongPress,
      child: Container(
        color: Colors.white.withOpacity(0.95),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RaysPainter(color: raysColor),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(widget.food.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 40),
                  widget.food.imageUrl.startsWith('assets/') 
                    ? Image.asset(widget.food.imageUrl, width: 120, height: 120)
                    : Image.file(File(widget.food.imageUrl), width: 120, height: 120),
                  const SizedBox(height: 40),
                  const Text('탭하여 계속', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  final Color color;
  _RaysPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16) * 3.14159 * 2;
      final x = size.width / 2 + size.width * 1.2 * math.cos(angle);
      final y = size.height / 2 + size.height * 1.2 * math.sin(angle);
      canvas.drawLine(Offset(size.width / 2, size.height / 2), Offset(x, y), paint..strokeWidth = 24);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FoodGridScreen extends StatefulWidget {
  const FoodGridScreen({super.key});

  @override
  State<FoodGridScreen> createState() => _FoodGridScreenState();
}

class _FoodGridScreenState extends State<FoodGridScreen> {
  List<Food> selectedFoods = [];
  List<Food> allFoods = []; // Hive에서 로드된 모든 음식
  List<Food> availableFoods = []; // 사용 가능한 음식 (레시피가 없는 원재료들)
  Food? resultFood;
  bool isCombinationFailed = false; // 조합 실패 상태
  Food? selectedFoodForDetail; // 상세 정보를 보여줄 재료
  Set<int> ownedRecipeIds = {}; // 획득한 레시피 id 목록
  bool isLoading = true; // 로딩 상태

  @override
  void initState() {
    super.initState();
    _loadFoodsFromHive();
  }

  /// Hive에서 음식 데이터를 로드합니다.
  Future<void> _loadFoodsFromHive() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Hive에서 모든 음식 데이터 로드
      final hiveFoods = await HiveHelper.instance.getAllFoods();
      
      // Food 객체로 변환 (이미 Food 타입이므로 그대로 사용)
      final List<Food> foods = hiveFoods;

      setState(() {
        allFoods = foods;
        // 레시피가 없는 원재료들만 사용 가능한 음식으로 설정
        availableFoods = foods.where((f) => f.recipes == null).toList();
        isLoading = false;
      });

      print('✅ Hive에서 ${foods.length}개의 음식 데이터 로드 완료');
    } catch (e) {
      print('❌ Hive 데이터 로드 실패: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addToCombinationBox(Food food) {
    if (selectedFoods.length >= 3) return;
    setState(() {
      selectedFoods.add(food);
      resultFood = null; // 재료가 바뀌면 항상 결과 초기화
      isCombinationFailed = false;
    });
  }

  void _removeFromCombinationBox(Food food) {
    setState(() {
      selectedFoods.remove(food);
      resultFood = null; // 재료가 바뀌면 항상 결과 초기화
      isCombinationFailed = false;
    });
  }

  void _clearCombinationBox() {
    setState(() {
      selectedFoods.clear();
      resultFood = null; // 재료가 바뀌면 항상 결과 초기화
      isCombinationFailed = false;
    });
  }

  void _combineIngredients() {
    if (selectedFoods.length < 2) {
      isCombinationFailed = true;
      setState(() {});
      return;
    }
    
    // 선택된 재료들의 ID로 레시피 매칭
    final selectedIds = selectedFoods.map((f) => f.id).toList()..sort();
    
    // 모든 음식 중에서 레시피가 있는 것들을 확인
    for (final food in allFoods) {
      if (food.recipes != null) {
        final recipeIds = List<int>.from(food.recipes!)..sort();
        if (recipeIds.length == selectedIds.length &&
            const ListEquality().equals(recipeIds, selectedIds)) {
          setState(() {
            resultFood = food;
            ownedRecipeIds.add(food.id);
            isCombinationFailed = false;
          });
          return;
        }
      }
    }
    
    // 매칭되는 레시피가 없으면 실패
    setState(() {
      resultFood = null;
      isCombinationFailed = true;
    });
  }

  void _showFoodDetail(Food food) {
    setState(() {
      selectedFoodForDetail = food;
    });
  }

  void _hideFoodDetail() {
    setState(() {
      selectedFoodForDetail = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = allFoods.length;
    final ownedCount = ownedRecipeIds.length + selectedFoods.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      '$ownedCount/$totalCount',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: availableFoods.isEmpty
                              ? const Center(
                                  child: Text(
                                    '사용 가능한 재료가 없습니다.',
                                    style: TextStyle(fontSize: 18, color: Colors.grey),
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 0.6,
                                      ),
                                  itemCount: availableFoods.length,
                                  itemBuilder: (context, index) {
                                    final food = availableFoods[index];
                                    return GestureDetector(
                                      onTap: () => _addToCombinationBox(food),
                                      onLongPress: () => _showFoodDetail(food),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Card(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 2,
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Builder(
                                                builder: (context) {
                                                  // 이미지 경로 로그 출력
                                                  print('🖼️ 이미지 로드 시도: ${food.imageUrl}');
                                                  
                                                  // 파일 존재 여부 확인 (로컬 파일인 경우)
                                                  if (food.imageUrl.startsWith('/')) {
                                                    final file = File(food.imageUrl);
                                                    file.exists().then((exists) {
                                                      print('🖼️ 파일 존재 여부: $exists - ${food.imageUrl}');
                                                    });
                                                  }
                                                  
                                                  return food.imageUrl.startsWith('assets/') 
                                                    ? Image.asset(
                                                        food.imageUrl,
                                                        width: 48,
                                                        height: 48,
                                                        fit: BoxFit.contain,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          print('❌ Assets 이미지 로드 실패: ${food.imageUrl}');
                                                          print('❌ 에러: $error');
                                                          return Container(
                                                            width: 48,
                                                            height: 48,
                                                            color: Colors.grey[300],
                                                            child: const Icon(Icons.error),
                                                          );
                                                        },
                                                      )
                                                    : Image.file(
                                                        File(food.imageUrl), // 이미 전체 경로가 저장되어 있음
                                                        width: 48,
                                                        height: 48,
                                                        fit: BoxFit.contain,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          print('❌ 로컬 파일 이미지 로드 실패: ${food.imageUrl}');
                                                          print('❌ 파일 존재 여부: ${File(food.imageUrl).existsSync()}');
                                                          print('❌ 에러: $error');
                                                          return Container(
                                                            width: 48,
                                                            height: 48,
                                                            color: Colors.grey[300],
                                                            child: const Icon(Icons.error),
                                                          );
                                                        },
                                                      );
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            food.name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  color: Colors.grey.shade100,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(3, (i) {
                          if (i < selectedFoods.length) {
                            final food = selectedFoods[i];
                            return GestureDetector(
                              onTap: () => _removeFromCombinationBox(food),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.all(6),
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    food.imageUrl.startsWith('assets/') 
                                      ? Image.asset(food.imageUrl, height: 32)
                                      : Image.file(File(food.imageUrl), height: 32),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Image.asset(
                                'assets/images/cooking.png',
                                width: 32,
                                height: 32,
                                color: Colors.white,
                              ),
                            );
                          }
                        }),
                        const SizedBox(width: 12),
                        // 조합/완성품/X 영역
                        Builder(
                          builder: (context) {
                            final canCombine = selectedFoods.length >= 2;
                            Food? matchedRecipe;
                            if (canCombine) {
                              // 조합된 재료 id 리스트
                              final selectedIds = selectedFoods.map((f) => f.id).toList()..sort();
                              for (final food in allFoods) {
                                if (food.recipes != null) {
                                  final recipeIds = List<int>.from(food.recipes!)..sort();
                                  if (recipeIds.length == selectedIds.length &&
                                      const ListEquality().equals(recipeIds, selectedIds)) {
                                    matchedRecipe = food;
                                    break;
                                  }
                                }
                              }
                            }
                            // 조합 버튼을 눌렀을 때의 결과 상태
                            bool showResult = resultFood != null || isCombinationFailed;
                            if (showResult) {
                              if (resultFood != null && matchedRecipe != null) {
                                // 완성품 노출
                                return Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: matchedRecipe.imageUrl.startsWith('assets/') 
                                    ? Image.asset(matchedRecipe.imageUrl, height: 48)
                                    : Image.file(File(matchedRecipe.imageUrl), height: 48),
                                );
                              } else {
                                // X 표시
                                return Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                );
                              }
                            } else if (canCombine) {
                              // cooking.png 활성화(컬러, 하늘색 배경, 작게)
                              return GestureDetector(
                                onTap: () async {
                                  if (matchedRecipe != null) {
                                    setState(() {
                                      resultFood = matchedRecipe;
                                      ownedRecipeIds.add(matchedRecipe!.id);
                                      isCombinationFailed = false;
                                      if (!availableFoods.any((f) => f.id == matchedRecipe!.id)) {
                                        availableFoods.add(matchedRecipe!);
                                      }
                                    });
                                    // 완성 오버레이 띄우기
                                    await showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => CompleteOverlay(
                                        food: matchedRecipe!,
                                        onClose: () {
                                          Navigator.of(context).pop();
                                          _clearCombinationBox();
                                        },
                                        onLongPress: () {},
                                      ),
                                    );
                                  } else {
                                    setState(() {
                                      resultFood = null;
                                      isCombinationFailed = true;
                                    });
                                  }
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlue[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Image.asset(
                                    'assets/images/cooking.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              );
                            } else {
                              // 비활성화(흑백, 투명 배경, 작게)
                              return Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ColorFiltered(
                                  colorFilter: const ColorFilter.matrix(<double>[
                                    0.2126, 0.7152, 0.0722, 0, 0,
                                    0.2126, 0.7152, 0.0722, 0, 0,
                                    0.2126, 0.7152, 0.0722, 0, 0,
                                    0, 0, 0, 1, 0,
                                  ]),
                                  child: Image.asset(
                                    'assets/images/cooking.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selectedFoodForDetail != null)
            Positioned.fill(
              child: FoodDetailModal(
                food: selectedFoodForDetail!,
                allFoods: allFoods, // 모든 음식 목록 전달
                onIngredientTap: (f) => setState(() => selectedFoodForDetail = f),
                onClose: _hideFoodDetail,
              ),
            ),
        ],
      ),
    );
  }
}
