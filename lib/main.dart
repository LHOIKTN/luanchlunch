import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:launchlunch/data/supabase/supabase_client.dart';
import 'package:launchlunch/data/hive/hive_helper.dart';
import 'package:launchlunch/features/splash/screen.dart';
import 'package:launchlunch/theme/app_theme.dart';

void main() async {
  // Flutter 바인딩 초기화를 먼저 수행
  WidgetsFlutterBinding.ensureInitialized();

  // 시스템 UI 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 환경 변수 로드 (실패해도 계속 진행)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('⚠️ 환경 변수 로드 실패, 기본값 사용');
  }

  // Hive 초기화 (앱 실행에 필수)
  try {
    await HiveHelper.instance.init();
  } catch (e) {
    print('❌ Hive 초기화 실패: $e');
  }

  // Supabase 초기화 (실패해도 앱 실행 계속)
  try {
    await initSupabase();
  } catch (e) {
    print('⚠️ Supabase 초기화 실패, 오프라인 모드로 실행');
  }

  // 앱 실행
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '한입두입',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
