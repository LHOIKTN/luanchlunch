import 'package:flutter/material.dart';
import 'package:launchlunch/data/supabase/api_service.dart';
import 'package:launchlunch/data/supabase/supabase_client.dart';
import 'package:launchlunch/data/sqflite/sqflite_helper.dart';
import 'package:intl/intl.dart';
import 'package:launchlunch/utils/download_image.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:launchlunch/screens/inventory.dart';
import 'globals.dart';
import 'utils/recipe_utils.dart';
import 'models/recipes.dart';

Future<void> deleteDatabaseFile() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'app_data.db');
  await deleteDatabase(path);
  print('📛 DB 삭제됨: $path');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  // await deleteDatabaseFile();
  await SqfliteHelper.instance.database;
  await initSupabase();
  // await syncInitialData();

  // TODO: 실제 DB에서 레시피를 불러오는 함수로 교체
  List<Recipes> recipesList = await fetchRecipesFromDB();
  globalRecipeMap = RecipeUtils.groupByResult(recipesList);

  runApp(const MyApp());
}

Future<void> syncInitialData() async {
  final api = SupabaseApi();
  try {
    // 마지막 푸드 목록 조회
    final lastFoodId = await SqfliteHelper.instance.getLastFoodId();
    // 추가 푸드 있는지 조회
    final foods = await api.getFoodDatas(lastFoodId);
    if (foods.isNotEmpty) {
      print(foods);
      for (final food in foods) {
        final id = food['id'];
        final name = food['name'];
        final imageUrl = food['image_url'];
        final savedPath = await downloadAndSaveImage(imageUrl);
        if (savedPath == null) continue;
        await SqfliteHelper.instance.insertFood(id, name, savedPath);
      }
    }
    final checked = await SqfliteHelper.instance.getFoods();
    print('---foods in DB---');
    print(checked);

    final lastRecipeId = await SqfliteHelper.instance.getLastRecipeId();
    print(lastRecipeId);
    final recipes = await api.getLatestRecies(lastRecipeId);
    print(recipes);

    final today = DateTime.now();
    final formatted = DateFormat('yyyy-MM-dd').format(today);

    print(formatted);
    final menus = await api.getMenusByDate('2025-07-11');
    print('------------');
    print(menus);
  } catch (e) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: FoodGridScreen());
  }
}
