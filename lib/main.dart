import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:launchlunch/data/supabase/supabase_client.dart';
import 'package:launchlunch/data/hive/hive_helper.dart';
import 'package:launchlunch/features/splash/screen.dart';
import 'package:launchlunch/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Supabase 초기화 실패해도 앱 실행 계속
  try {
    await initSupabase();
    print('✅ Supabase 초기화 성공');
  } catch (e) {
    print('⚠️ Supabase 초기화 실패, 오프라인 모드로 실행: $e');
  }

  await HiveHelper.instance.init();

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
