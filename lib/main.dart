import 'package:flutter/material.dart';
import 'package:launchlunch/data/hive/init.dart';
import 'package:hive/hive.dart';
import 'package:launchlunch/models/daily_data.dart';
import 'package:launchlunch/models/ingredient.dart';
import 'package:launchlunch/data/supabase/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();

  final api = SupabaseApi();
  final menus = await api.getMenusByDate('2025-07-11');
  print('------------');
  print(menus);

  // 테스트: 임시 데이터 저장
  final box = Hive.box<DailyData>('daily_data');
  final testDate = '2099-01-01'; // 미래 날짜로 저장해 충돌 방지

  // if (!box.containsKey(testDate)) {
  //   await box.put(
  //     testDate,
  //     DailyData(
  //       date: testDate,
  //       menuText: ['미역국', '배추김치', '블루베리쿠키바'],
  //       ingredients: [
  //         Ingredient(
  //           id: "Seaweed",
  //           name: '미역',
  //           imagePath:
  //               'https://tcszpiaymqtftcbaydwy.supabase.co/storage/v1/object/public/images/Seaweed.png',
  //         ),
  //         Ingredient(
  //           id: "napacabbage",
  //           name: '배추',
  //           imagePath:
  //               'https://tcszpiaymqtftcbaydwy.supabase.co/storage/v1/object/public/images/NapaCabbage.png',
  //         ),
  //         Ingredient(
  //           id: 'blueberry',
  //           name: '블루베리',
  //           imagePath:
  //               'https://tcszpiaymqtftcbaydwy.supabase.co/storage/v1/object/public/images/Blueberry.png',
  //         ),
  //       ],
  //     ),
  //   );
  //   print('✅ 테스트 데이터 저장됨');
  // } else {
  //   print('⚠️ 테스트 데이터 이미 있음');
  // }

  // 저장된 데이터 확인
  // final saved = box.get(testDate);
  // print('📅 날짜: ${saved?.date}');
  // print('📜 메뉴: ${saved?.menuText}');
  // print('🍽️ 재료: ${saved?.ingredients.map((e) => e.name).join(', ')}');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('테스트 완료')),
        body: const Center(child: Text('콘솔에서 저장 확인 완료 ✅')),
      ),
    );
  }
}
