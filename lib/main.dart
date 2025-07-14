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
import 'package:launchlunch/utils/preload.dart';

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
  await initSupabase();
  // await syncInitialData();

  // TODO: 실제 DB에서 레시피를 불러오는 함수로 교체
  // List<Recipes> recipesList = await fetchRecipesFromDB();
  // globalRecipeMap = RecipeUtils.groupByResult(recipesList);

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: FoodGridScreen());
    // return MaterialApp(home: Text("hello"));
  }
}
