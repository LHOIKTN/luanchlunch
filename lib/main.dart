import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:launchlunch/data/supabase/api_service.dart';
import 'package:launchlunch/data/supabase/supabase_client.dart';
import 'package:intl/intl.dart';
import 'package:launchlunch/utils/download_image.dart';
import 'package:path/path.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:launchlunch/screens/inventory.dart';
import 'package:launchlunch/utils/preload.dart';
import 'package:launchlunch/data/hive/hive_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initSupabase();
  
  // Web 환경에서는 Hive 초기화 건너뛰기
  if (!kIsWeb) {
    await HiveHelper.instance.init();
  }
  
  // 데이터 프리로드 실행
  await PreloadData.preloadAllData();
  
  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: FoodGridScreen());
  }
}
