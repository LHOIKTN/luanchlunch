import 'package:hive/hive.dart';

part 'meal.g.dart';

@HiveType(typeId: 1)
class DailyMeal extends HiveObject {
  @HiveField(0)
  final String mealDate;

  @HiveField(1)
  final List<String> menus;

  @HiveField(2)
  final List<int> foods;

  DailyMeal({
    required this.mealDate,
    required this.menus,
    required this.foods,
  });

  // Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'meal_date': mealDate,
      'menus': menus,
      'foods': foods,
    };
  }

  // Create from Supabase data
  factory DailyMeal.fromSupabase(Map<String, dynamic> map) {
    return DailyMeal(
      mealDate: map['meal_date'] ?? '',
      menus: List<String>.from(map['menus'] ?? []),
      foods: List<int>.from(map['foods'] ?? []),
    );
  }

  // Create copy with updated data
  DailyMeal copyWith({
    String? mealDate,
    List<String>? menus,
    List<int>? foods,
  }) {
    return DailyMeal(
      mealDate: mealDate ?? this.mealDate,
      menus: menus ?? this.menus,
      foods: foods ?? this.foods,
    );
  }

  @override
  String toString() {
    return 'DailyMeal(mealDate: $mealDate, menus: $menus, foods: $foods)';
  }
}
