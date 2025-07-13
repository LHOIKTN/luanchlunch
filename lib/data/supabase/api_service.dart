import 'supabase_client.dart';

class SupabaseApi {
  /// 오늘 날짜의 메뉴,재료 가져오기
  Future<Map<String, dynamic>> getMenusByDate(String date) async {
    final response = await supabase
        .from('meals')
        .select('*, menus(name, foods(*))')
        .eq('meal_date', date);

    final menus = <String>[];
    final foodSet = <int, Map<String, dynamic>>{};

    for (final item in response) {
      final menu = item['menus'];
      if (menu == null) continue;

      if (menu['name'] != null) {
        menus.add(menu['name']);
      }

      final food = menu['foods'];
      if (food != null && food['id'] != null) {
        foodSet[food['id']] = food;
      }
    }

    return {'meal_date': date, "menus": menus, 'food': foodSet.values.toList()};
  }

  Future<List<Map<String, dynamic>>> getFoodDatas(int lastFoodId) async {
    final response = await supabase
        .from('foods')
        .select('*')
        .gt('id', lastFoodId) // id > lastFoodId
        .order("id", ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getLatestRecies(int lastRecipeId) async {
    print(lastRecipeId);
    final test = await supabase.from('recipes').select('*');
    print(test);

    final response = await supabase
        .from('recipes')
        .select('id, result_id, required_id')
        .gt('id', lastRecipeId)
        .order("id", ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  //   /// 메뉴 UUID를 기반으로 메뉴명, 재료 UUID 가져오기
  //   Future<List<Map<String, dynamic>>> getMenus(List<String> uuids) async {
  //     final response = await supabase
  //         .from('menus')
  //         .select('uuid, name, ingredient_uuid')
  //         .inFilter('uuid', uuids);

  //     return (response as List).cast<Map<String, dynamic>>();
  //   }

  //   /// 재료 UUID 리스트 → 이름, 이미지 URL 가져오기
  //   Future<List<Map<String, dynamic>>> getIngredients(List<String> uuids) async {
  //     final response = await supabase
  //         .from('ingredients')
  //         .select('uuid, name, image_url')
  //         .inFilter('uuid', uuids);

  //     return (response as List).cast<Map<String, dynamic>>();
  //   }
}
