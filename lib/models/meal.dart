import 'package:hive/hive.dart';

part 'meal.g.dart';

@HiveType(typeId: 1)
class DailyMeal extends HiveObject {
  @HiveField(0)
  final String lunchDate;

  @HiveField(1)
  final String menuList;

  @HiveField(2)
  final List<int> foods;

  @HiveField(3)
  final bool isAcquired;

  DailyMeal({
    required this.lunchDate,
    required this.menuList,
    required this.foods,
    this.isAcquired = false,
  });

  // Convert to Map for Supabase
  Map<String, dynamic> toMap() {
    return {
      'lunch_date': lunchDate,
      'menu_list': menuList,
      'foods': foods,
      'is_acquired': isAcquired,
    };
  }

  // Create from Supabase data
  factory DailyMeal.fromSupabase(Map<String, dynamic> map) {
    return DailyMeal(
      lunchDate: map['lunch_date'] ?? '',
      menuList: map['menu_list'] ?? '',
      foods: List<int>.from(map['foods'] ?? []),
      isAcquired: map['is_acquired'] ?? false,
    );
  }

  // Create copy with updated data
  DailyMeal copyWith({
    String? lunchDate,
    String? menuList,
    List<int>? foods,
    bool? isAcquired,
  }) {
    return DailyMeal(
      lunchDate: lunchDate ?? this.lunchDate,
      menuList: menuList ?? this.menuList,
      foods: foods ?? this.foods,
      isAcquired: isAcquired ?? this.isAcquired,
    );
  }

  @override
  String toString() {
    return 'DailyMeal(lunchDate: $lunchDate, menuList: $menuList, foods: $foods, isAcquired: $isAcquired)';
  }
}
