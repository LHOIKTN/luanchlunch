import 'supabase_client.dart';

class SupabaseApi {
  // Supabase 연결 상태 확인
  bool get isConnected => isSupabaseInitialized;

  // 안전한 API 호출을 위한 래퍼
  Future<T?> _safeApiCall<T>(Future<T?> Function() apiCall) async {
    if (!isConnected) {
      print('⚠️ Supabase 연결되지 않음, 오프라인 모드');
      return null;
    }

    try {
      return await apiCall();
    } catch (e) {
      print('⚠️ Supabase API 호출 실패: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createUser() async {
    return await _safeApiCall(() async {
      final response = await supabase.from('users').insert({}).select();
      return response[0];
    });
  }

  Future<Map<String, dynamic>?> getUserInfo(
      String userUUID, String lastUpdatedAt) async {
    return await _safeApiCall(() async {
      final response = await supabase
          .from('users')
          .select()
          .eq('uuid', userUUID)
          .gt('updated_at', lastUpdatedAt);
      print(response);
      return response.isNotEmpty
          ? Map<String, dynamic>.from(response[0])
          : null;
    });
  }

  // Updated to use updated_at for incremental sync
  Future<List<Map<String, dynamic>>?> getFoodDatas(String updatedAt) async {
    return await _safeApiCall(() async {
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
            print('❌ 최대 재시도 횟수 초과, null 반환');
            return null;
          }

          // 1초 대기 후 재시도
          await Future.delayed(Duration(seconds: 1));
        }
      }

      return null;
    });
  }

  Future<List<Map<String, dynamic>>> getRecipes(String updatedAt) async {
    print('🔍 [레시피 조회] Supabase recipes 테이블 조회 시작...');
    print('📅 [레시피 조회] updatedAt 조건: $updatedAt');

    final response = await supabase
        .from('recipes')
        .select('result_id, required_id, updated_at, quantity')
        .gte('updated_at', updatedAt)
        .order("result_id, updated_at", ascending: true);

    final rawData = List<Map<String, dynamic>>.from(response);
    print('📊 [레시피 조회] Supabase 응답: ${rawData.length}개 레시피 로우');

    // food_id 20(블루베리주먹밥) 특별 추적
    final food20Recipes =
        rawData.where((row) => row['result_id'] == 20).toList();
    if (food20Recipes.isNotEmpty) {
      print('🎯 [블루베리주먹밥 추적] food_id 20 레시피 발견: ${food20Recipes.length}개 로우');
      for (final recipe in food20Recipes) {
        print(
            '📝 [블루베리주먹밥 추적] result_id=20, required_id=${recipe['required_id']}, quantity=${recipe['quantity']}, updated_at=${recipe['updated_at']}');
      }
    } else {
      print('❌ [블루베리주먹밥 추적] food_id 20에 대한 레시피 로우가 Supabase 응답에 없습니다!');
      print('🔍 [블루베리주먹밥 추적] updatedAt 조건 확인: $updatedAt');
      print(
          '🔍 [블루베리주먹밥 추적] 전체 result_id 목록: ${rawData.map((r) => r['result_id']).toSet().toList()..sort()}');

      // food_id 20에 대한 직접 조회 시도
      await _checkFood20Directly();
    }

    // 받아온 원시 데이터 상세 로그
    for (int i = 0; i < rawData.length && i < 10; i++) {
      final row = rawData[i];
      print(
          '📝 [레시피 조회] 원시 데이터 $i: result_id=${row['result_id']}, required_id=${row['required_id']}, quantity=${row['quantity']}, updated_at=${row['updated_at']}');
    }
    if (rawData.length > 10) {
      print('📝 [레시피 조회] ... 및 ${rawData.length - 10}개 더');
    }

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
        if (resultId == 20) {
          print('🆕 [블루베리주먹밥 추적] 새로운 result_id 그룹 생성: $resultId');
        } else {
          print('🆕 [레시피 조회] 새로운 result_id 그룹 생성: $resultId');
        }
      }

      // required_id 추가
      for (int i = 0; i < quantity; i += 1) {
        groupedRecipes[resultId]!['required_ids'].add(requiredId);
      }
      if (resultId == 20) {
        print(
            '➕ [블루베리주먹밥 추적] result_id=$resultId에 required_id=$requiredId를 ${quantity}개 추가');
      } else {
        print(
            '➕ [레시피 조회] result_id=$resultId에 required_id=$requiredId를 ${quantity}개 추가');
      }
    }

    final groupedList = groupedRecipes.values.toList();
    print('🎯 [레시피 조회] 최종 그룹핑된 레시피: ${groupedList.length}개');

    // food_id 20 최종 확인
    final food20Final =
        groupedList.where((group) => group['result_id'] == 20).toList();
    if (food20Final.isNotEmpty) {
      print('✅ [블루베리주먹밥 추적] 최종 그룹핑 결과에 food_id 20 포함됨!');
      for (final group in food20Final) {
        print(
            '🎯 [블루베리주먹밥 추적] 최종: result_id=${group['result_id']}, required_ids=${group['required_ids']}, updated_at=${group['updated_at']}');
      }
    } else {
      print('❌ [블루베리주먹밥 추적] 최종 그룹핑 결과에 food_id 20이 없습니다!');
    }

    // 그룹핑된 결과 상세 로그 (20이 아닌 것들)
    for (final group in groupedList) {
      if (group['result_id'] != 20) {
        print(
            '📋 [레시피 조회] 그룹: result_id=${group['result_id']}, required_ids=${group['required_ids']}, updated_at=${group['updated_at']}');
      }
    }

    return groupedList;
  }

  /// 특정 음식의 레시피 직접 조회
  Future<List<Map<String, dynamic>>> getSpecificFoodRecipe(int foodId) async {
    print('🔍 [특정 레시피 조회] food_id $foodId 레시피 직접 조회 시작...');

    try {
      final response = await supabase
          .from('recipes')
          .select('result_id, required_id, updated_at, quantity')
          .eq('result_id', foodId);

      final rawData = List<Map<String, dynamic>>.from(response);
      print('📊 [특정 레시피 조회] food_id $foodId 조회 결과: ${rawData.length}개');

      if (rawData.isEmpty) {
        return [];
      }

      // result_id로 그룹핑
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

        for (int i = 0; i < quantity; i += 1) {
          groupedRecipes[resultId]!['required_ids'].add(requiredId);
        }
      }

      final result = groupedRecipes.values.toList();
      print(
          '🎯 [특정 레시피 조회] food_id $foodId 최종 결과: ${result.first['required_ids']}');

      return result;
    } catch (e) {
      print('❌ [특정 레시피 조회] food_id $foodId 조회 실패: $e');
      return [];
    }
  }

  /// food_id 20에 대한 직접 조회
  Future<void> _checkFood20Directly() async {
    try {
      print('🔍 [블루베리주먹밥 직접조회] food_id 20에 대한 모든 레시피 직접 조회 시작...');

      final directResponse = await supabase
          .from('recipes')
          .select('result_id, required_id, updated_at, quantity')
          .eq('result_id', 20);

      final directData = List<Map<String, dynamic>>.from(directResponse);
      print('📊 [블루베리주먹밥 직접조회] food_id 20 직접 조회 결과: ${directData.length}개');

      if (directData.isNotEmpty) {
        print('✅ [블루베리주먹밥 직접조회] DB에 food_id 20 레시피 존재함!');
        for (final recipe in directData) {
          print(
              '📝 [블루베리주먹밥 직접조회] result_id=20, required_id=${recipe['required_id']}, quantity=${recipe['quantity']}, updated_at=${recipe['updated_at']}');
        }

        // 가장 최신 updated_at 확인
        final latestUpdatedAt = directData
            .map((r) => r['updated_at'] as String)
            .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
        print(
            '🕐 [블루베리주먹밥 직접조회] food_id 20의 가장 최신 updated_at: $latestUpdatedAt');
      } else {
        print('❌ [블루베리주먹밥 직접조회] DB에 food_id 20 레시피가 전혀 없음!');
      }
    } catch (e) {
      print('❌ [블루베리주먹밥 직접조회] 직접 조회 실패: $e');
    }
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

  // Insert inventory data to Supabase (insert only - 이미 있으면 무시)
  Future<Map<String, dynamic>> insertInventory(
      List<Map<String, dynamic>> inventoryData) async {
    try {
      print('🔄 인벤토리 데이터 insert 시작: ${inventoryData.length}개');

      int successCount = 0;
      int failCount = 0;
      int duplicateCount = 0;
      List<String> errors = [];

      // 개별 아이템별로 처리하여 실패 내성 향상
      for (final item in inventoryData) {
        try {
          // inventory 테이블 구조에 맞게 데이터 정리
          final inventoryItem = {
            'user_uuid': item['user_uuid'],
            'food_id': item['food_id'],
            'acquired_at': item['acquired_at'],
          };

          // insert 시도 (이미 있으면 무시)
          final response =
              await supabase.from('inventory').insert(inventoryItem).select();

          successCount++;
          print('✅ 인벤토리 아이템 추가: food_id=${inventoryItem['food_id']}');
        } catch (e) {
          // 중복 키 오류인 경우 무시
          if (e.toString().contains('duplicate key') ||
              e.toString().contains('already exists') ||
              e.toString().contains('violates unique constraint')) {
            duplicateCount++;
            print('ℹ️ 이미 존재하는 아이템 무시: food_id=${item['food_id']}');
          } else {
            failCount++;
            final error = '❌ food_id=${item['food_id']}: $e';
            errors.add(error);
            print(error);
          }
        }
      }

      print(
          '📊 인벤토리 insert 완료: 추가 ${successCount}개, 중복 ${duplicateCount}개, 실패 ${failCount}개');

      return {
        'success': failCount == 0, // 실패한 것이 없어야 true
        'partial_success': successCount > 0, // 일부라도 성공하면 true
        'processed_count': successCount,
        'success_count': successCount,
        'duplicate_count': duplicateCount,
        'fail_count': failCount,
        'errors': errors,
      };
    } catch (e) {
      print('❌ 인벤토리 insert 전체 실패: $e');
      return {
        'success': false,
        'partial_success': false,
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
        .from('daily_lunch_for_app')
        .select()
        .gt('lunch_date', lastMealDate)
        .order('lunch_date', ascending: true);

    print('📊 Supabase 응답: ${response.length}개');
    return List<Map<String, dynamic>>.from(response);
  }

  // Get meals by date range
  Future<List<Map<String, dynamic>>> getMealsByDateRange(
      String startDate, String endDate) async {
    final response = await supabase
        .from('daily_lunch_for_app')
        .select()
        .gte('lunch_date', startDate)
        .lte('lunch_date', endDate)
        .order('lunch_date', ascending: true);

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

  // Add basic ingredients to user inventory (insert only - 이미 있으면 무시)
  Future<Map<String, dynamic>> addBasicIngredientsToInventory(
      String userUUID, List<int> foodIds) async {
    try {
      print('🔄 기본 재료 인벤토리 insert 시작: $userUUID -> $foodIds');

      final now = DateTime.now().toIso8601String();
      final inventoryData = foodIds
          .map((foodId) => {
                'user_uuid': userUUID,
                'food_id': foodId,
                'acquired_at': now,
              })
          .toList();

      final result = await insertInventory(inventoryData);

      if (result['partial_success'] == true) {
        print('✅ 기본 재료 인벤토리 insert 완료: 추가 ${result['success_count']}개');
        if (result['duplicate_count'] > 0) {
          print('ℹ️ 이미 존재하는 재료: ${result['duplicate_count']}개');
        }
        if (result['fail_count'] > 0) {
          print('⚠️ 실패: ${result['fail_count']}개');
        }
        return {
          'success': result['success'],
          'partial_success': result['partial_success'],
          'data': result,
        };
      } else {
        print('❌ 기본 재료 인벤토리 insert 전체 실패');
        return {
          'success': false,
          'error': result['error'],
        };
      }
    } catch (e) {
      print('❌ 기본 재료 인벤토리 insert 실패: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get ranking data with pagination
  Future<List<Map<String, dynamic>>> getRanking(
      {int? limit, int? offset}) async {
    try {
      var query =
          supabase.from('ranking').select('*').order('rank', ascending: true);

      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ 랭킹 데이터 요청 실패: $e');
      rethrow;
    }
  }

  // Get user's own ranking
  Future<Map<String, dynamic>?> getUserRanking(String userUUID) async {
    try {
      final response = await supabase
          .from('ranking')
          .select('*')
          .eq('uuid', userUUID)
          .single();

      return response;
    } catch (e) {
      print('❌ 사용자 랭킹 조회 실패: $e');
      return null;
    }
  }
}
