import 'dart:io';
import 'package:flutter/services.dart';
import 'assets_scanner.dart';

class AssetImageManager {
  static final AssetImageManager _instance = AssetImageManager._internal();
  factory AssetImageManager() => _instance;
  AssetImageManager._internal();

  final AssetsScanner _assetsScanner = AssetsScanner();

  /// assets에 있는 이미지 목록을 동적으로 로드
  Future<Set<String>> _loadAssetImages() async {
    return await _assetsScanner.scanImageAssets();
  }

  /// 이미지 경로가 assets에 있는지 확인
  Future<bool> isAssetImage(String imagePath) async {
    final assetImages = await _loadAssetImages();
    return assetImages.contains(imagePath);
  }

  /// 이미지 경로가 로컬 파일인지 확인
  bool isLocalFile(String imagePath) {
    return imagePath.startsWith('/') && File(imagePath).existsSync();
  }

  /// 이미지 경로가 Supabase URL인지 확인
  bool isSupabaseUrl(String imagePath) {
    return imagePath.startsWith('http') && imagePath.contains('supabase');
  }

  /// 이미지 로드 가능 여부 확인
  Future<bool> canLoadImage(String imagePath) async {
    if (await isAssetImage(imagePath)) {
      try {
        await rootBundle.load(imagePath);
        return true;
      } catch (e) {
        print('❌ Assets 이미지 로드 실패: $imagePath - $e');
        return false;
      }
    } else if (isLocalFile(imagePath)) {
      return File(imagePath).existsSync();
    } else if (isSupabaseUrl(imagePath)) {
      // Supabase URL은 항상 로드 가능하다고 가정 (실제로는 네트워크 상태 확인 필요)
      return true;
    }
    return false;
  }

  /// 이미지 타입에 따른 적절한 경로 반환
  Future<String> getImagePath(String imagePath) async {
    if (await isAssetImage(imagePath)) {
      return imagePath;
    } else if (isLocalFile(imagePath)) {
      return imagePath;
    } else if (isSupabaseUrl(imagePath)) {
      return imagePath;
    }
    // 기본값으로 assets의 기본 이미지 반환
    return 'assets/images/cooking.png';
  }

  /// 모든 assets 이미지 목록 반환
  Future<Set<String>> get assetImages async => await _loadAssetImages();

  /// assets 이미지 개수 반환
  Future<int> get assetImageCount async {
    final images = await _loadAssetImages();
    return images.length;
  }
} 