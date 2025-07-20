// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyMealAdapter extends TypeAdapter<DailyMeal> {
  @override
  final int typeId = 1;

  @override
  DailyMeal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyMeal(
      mealDate: fields[0] as String,
      menus: (fields[1] as List).cast<String>(),
      foods: (fields[2] as List).cast<int>(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyMeal obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.mealDate)
      ..writeByte(1)
      ..write(obj.menus)
      ..writeByte(2)
      ..write(obj.foods);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyMealAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
