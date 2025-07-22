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
      lunchDate: fields[0] as String,
      menuList: fields[1] as String,
      foods: (fields[2] as List).cast<int>(),
      isAcquired: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DailyMeal obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.lunchDate)
      ..writeByte(1)
      ..write(obj.menuList)
      ..writeByte(2)
      ..write(obj.foods)
      ..writeByte(3)
      ..write(obj.isAcquired);
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
