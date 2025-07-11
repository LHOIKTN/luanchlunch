// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyDataAdapter extends TypeAdapter<DailyData> {
  @override
  final int typeId = 0;

  @override
  DailyData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyData(
      date: fields[0] as String,
      menuText: (fields[1] as List).cast<String>(),
      ingredients: (fields[2] as List).cast<Ingredient>(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.menuText)
      ..writeByte(2)
      ..write(obj.ingredients);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
