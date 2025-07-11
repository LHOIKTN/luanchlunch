import 'package:hive_flutter/hive_flutter.dart';
import 'package:launchlunch/models/daily_data.dart';
import 'package:launchlunch/models/ingredient.dart'; // 추가

Future<void> initHive() async {
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(DailyDataAdapter());
  }

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(IngredientAdapter()); // 추가 등록
  }

  await Hive.openBox<DailyData>('daily_data');
}