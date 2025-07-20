import 'supabase_client.dart';

class SupabaseApi {
  Future<Map<String, dynamic>> createUser() async {
    final response = await supabase.from('users').insert({}).select();
    return response[0];
  }

  Future<Map<String, dynamic>> getUserInfo(
      String userUUID, String lastUpdatedAt) async {
    final response = await supabase
        .from('users')
        .select()
        .eq('uuid', userUUID)
        .gt('updated_at', lastUpdatedAt);
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
        .select('result_id, required_id, updated_at, quantity')
        .gte('updated_at', updatedAt)
        .order("result_id, updated_at", ascending: true);

    final rawData = List<Map<String, dynamic>>.from(response);

    // result_id로 그룹핑하고 required_id들을 수집
    final Map<int, Map<String, dynamic>> groupedRecipes = {};

    for (final recipe in rawData) {
      final int resultId = recipe['result_id'];
      final int requiredId = recipe['required_id'];
      final String updatedAt = recipe['updated_at'];
      final int quantity = recipe['quantity'];

      if (!groupedRecipes.containsKey(resultId)) {
        groupedRecipes[resultId] = {
          'result_id': resultId,
          'required_ids': <int>[],
          'updated_at': updatedAt,
        };
      }

      // required_id 추가
      for (int i = 0; i < quantity; i += 1) {
        groupedRecipes[resultId]!['required_ids'].add(requiredId);
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

  // Insert inventory data to Supabase (ignore if exists)
  Future<Map<String, dynamic>> insertInventory(
      List<Map<String, dynamic>> inventoryData) async {
    try {
      print('🔄 인벤토리 데이터 insert 시작: ${inventoryData.length}개');

      // insert 실행 (이미 있으면 무시)
      final response =
          await supabase.from('inventory').insert(inventoryData).select();

      print('✅ 인벤토리 insert 성공: ${response.length}개 처리됨');
      return {
        'success': true,
        'processed_count': response.length,
        'data': response,
      };
    } catch (e) {
      print('❌ 인벤토리 insert 실패: $e');
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

  // Get meals data with incremental sync
  Future<List<Map<String, dynamic>>> getMeals(String lastMealDate) async {
    final response = await supabase
        .from('daily_meals_for_app')
        .select()
        .gt('meal_date', lastMealDate)
        .order('meal_date', ascending: true);

    print('📊 Supabase 응답: ${response.length}개');
    return List<Map<String, dynamic>>.from(response);
  }

  // Get meals by date range
  Future<List<Map<String, dynamic>>> getMealsByDateRange(
      String startDate, String endDate) async {
    final response = await supabase
        .from('daily_meals_for_app')
        .select()
        .gte('meal_date', startDate)
        .lte('meal_date', endDate)
        .order('meal_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Update user nickname
  Future<Map<String, dynamic>> updateNickname(
      String userUUID, String nickname) async {
    try {
      print('🔄 닉네임 업데이트 시작: $userUUID -> $nickname');

      final response = await supabase
          .from('users')
          .update({'nickname': nickname})
          .eq('uuid', userUUID)
          .select();

      print('✅ 닉네임 업데이트 성공');
      return {
        'success': true,
        'data': response[0],
      };
    } catch (e) {
      print('❌ 닉네임 업데이트 실패: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Add basic ingredients to user inventory
  Future<Map<String, dynamic>> addBasicIngredientsToInventory(
      String userUUID, List<int> foodIds) async {
    try {
      print('🔄 기본 재료 인벤토리 추가 시작: $userUUID -> $foodIds');

      final now = DateTime.now().toIso8601String();
      final inventoryData = foodIds
          .map((foodId) => {
                'user_uuid': userUUID,
                'food_id': foodId,
                'acquired_at': now,
                'updated_at': now,
              })
          .toList();

      final response = await supabase
          .from('inventory')
          .upsert(
            inventoryData,
            onConflict: 'user_uuid,food_id',
          )
          .select();

      print('✅ 기본 재료 인벤토리 추가 성공: ${response.length}개');
      return {
        'success': true,
        'data': response,
      };
    } catch (e) {
      print('❌ 기본 재료 인벤토리 추가 실패: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
