import 'supabase_client.dart';

class SupabaseApi {
  /// 오늘 날짜의 메뉴 UUID들 가져오기
  Future<List<Object>> getMenusByDate(String date) async {
    final response = await supabase
        .from('meals')
        .select('*')
        .eq('meal_date', date);

    if (response is List) {
      final result = response;
      print(result);
      return result;
    }
    return [];
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
