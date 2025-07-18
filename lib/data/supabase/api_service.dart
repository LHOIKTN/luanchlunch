import 'supabase_client.dart';

class SupabaseApi {
  Future<Map<String, dynamic>> createUser() async {
    final response = await supabase.from('users').insert({}).select();
    return response[0];
  }

  Future<Map<String, dynamic>> getUserInfo(String userId, String lastUpdatedAt) async {
    final response = await supabase.from('users').select().eq('id', userId).gt('updated_at', lastUpdatedAt);
    print(response);
    return response[0];
  }

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

  // Updated to use updated_at for incremental sync
  Future<List<Map<String, dynamic>>> getFoodDatas(String updatedAt) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final response = await supabase
            .from('foods')
            .select('*')
            .gte('updated_at', updatedAt) // updated_at >= lastUpdatedAt
            .order("id", ascending: true);

        return List<Map<String, dynamic>>.from(response);
      } catch (e) {
        retryCount++;
        print('⚠️ 음식 데이터 요청 실패 (시도 $retryCount/$maxRetries): $e');

        if (retryCount >= maxRetries) {
          print('❌ 최대 재시도 횟수 초과');
          rethrow;
        }

        // 1초 대기 후 재시도
        await Future.delayed(Duration(seconds: 1));
      }
    }

    throw Exception('음식 데이터 요청 실패');
  }

  // Legacy method for backward compatibility
  Future<List<Map<String, dynamic>>> getFoodDatasById(int lastFoodId) async {
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

  Future<List<Map<String, dynamic>>> getRecipes(String updatedAt) async {
    final response = await supabase
        .from('recipes')
        .select('id, result_id, required_id, updated_at')
        .gte('updated_at', updatedAt)
        .order("result_id, updated_at", ascending: true);

    final rawData = List<Map<String, dynamic>>.from(response);

    // result_id로 그룹핑하고 required_id들을 수집
    final Map<int, Map<String, dynamic>> groupedRecipes = {};

    for (final recipe in rawData) {
      final int resultId = recipe['result_id'];
      final int requiredId = recipe['required_id'];
      final String updatedAt = recipe['updated_at'];

      if (!groupedRecipes.containsKey(resultId)) {
        groupedRecipes[resultId] = {
          'result_id': resultId,
          'required_ids': <int>[],
          'updated_at': updatedAt,
        };
      }

      // required_id 추가
      groupedRecipes[resultId]!['required_ids'].add(requiredId);

      // 가장 최신 updated_at으로 업데이트
      if (updatedAt.compareTo(groupedRecipes[resultId]!['updated_at']) > 0) {
        groupedRecipes[resultId]!['updated_at'] = updatedAt;
      }
    }

    return groupedRecipes.values.toList();
  }

  // Get user's inventory with incremental sync
  Future<List<Map<String, dynamic>>> getInventory(String updatedAt) async {
    final response = await supabase
        .from('inventory')
        .select('food_id, acquired_at, updated_at')
        .gte('updated_at', updatedAt)
        .order("food_id", ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Upsert inventory data to Supabase
  Future<Map<String, dynamic>> upsertInventory(List<Map<String, dynamic>> inventoryData) async {
    try {
      print('🔄 인벤토리 데이터 upsert 시작: ${inventoryData.length}개');
      
      // upsert 실행 (user_id, food_id가 복합 키라고 가정)
      final response = await supabase
          .from('inventory')
          .upsert(
            inventoryData,
            onConflict: 'user_id,food_id', // 복합 키 충돌 시 업데이트
          )
          .select();
      
      print('✅ 인벤토리 upsert 성공: ${response.length}개 처리됨');
      return {
        'success': true,
        'processed_count': response.length,
        'data': response,
      };
    } catch (e) {
      print('❌ 인벤토리 upsert 실패: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
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
