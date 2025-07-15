import 'package:flutter/services.dart';
import 'dart:convert'; // Added missing import for json

class AssetsScanner {
  static final AssetsScanner _instance = AssetsScanner._internal();
  factory AssetsScanner() => _instance;
  AssetsScanner._internal();

  Set<String>? _cachedAssetImages;

  /// assets/images 디렉토리의 모든 이미지 파일을 스캔
  Future<Set<String>> scanImageAssets() async {
    if (_cachedAssetImages != null) {
      return _cachedAssetImages!;
    }

    final Set<String> assetImages = {};
    
    try {
      // pubspec.yaml에 정의된 assets를 확인
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // assets/images/ 경로의 파일들만 필터링
      final imageAssets = manifestMap.keys
          .where((String key) => key.startsWith('assets/images/'))
          .where((String key) => _isImageFile(key))
          .toSet();
      
      assetImages.addAll(imageAssets);
      
      print('📁 Assets 스캔 완료: ${assetImages.length}개의 이미지 파일 발견');
      print('📁 발견된 이미지들: ${assetImages.toList()}');
      
    } catch (e) {
      print('❌ Assets 스캔 실패: $e');
      // 폴백: 일반적인 이미지 파일명들 시도
      await _fallbackScan(assetImages);
    }
    
    _cachedAssetImages = assetImages;
    return assetImages;
  }

  /// 이미지 파일 확장자 확인
  bool _isImageFile(String filePath) {
    final imageExtensions = ['.webp', '.png', '.jpg', '.jpeg', '.gif'];
    return imageExtensions.any((ext) => filePath.toLowerCase().endsWith(ext));
  }

  /// 폴백 스캔: 일반적인 이미지 파일명들을 시도
  Future<void> _fallbackScan(Set<String> assetImages) async {
    final commonImageNames = [
      'bean_sprout', 'blueberry', 'blueberry_rice', 'blueberry_rice_ball',
      'beef_seaweed_soup', 'chicken', 'cow', 'garlic', 'gochu', 'gochugaru',
      'green_onion', 'lettuce', 'napa_cabbage', 'ponytail_radish', 'potato',
      'rice', 'rice_ball', 'salt', 'seaweed', 'seaweed_soup', 'sesame_oil',
      'soy_sauce', 'sugar', 'cooking'
    ];
    
    final imageExtensions = ['.webp', '.png', '.jpg', '.jpeg'];
    
    for (final name in commonImageNames) {
      for (final extension in imageExtensions) {
        final assetPath = 'assets/images/$name$extension';
        if (await _isAssetAvailable(assetPath)) {
          assetImages.add(assetPath);
        }
      }
    }
  }

  /// assets에 특정 파일이 있는지 확인
  Future<bool> _isAssetAvailable(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 특정 이미지가 assets에 있는지 확인
  Future<bool> hasImage(String imagePath) async {
    final assets = await scanImageAssets();
    return assets.contains(imagePath);
  }

  /// 캐시 초기화
  void clearCache() {
    _cachedAssetImages = null;
  }
} 