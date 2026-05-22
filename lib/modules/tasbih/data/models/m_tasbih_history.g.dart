// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_tasbih_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MTasbihHistoryAdapter extends TypeAdapter<MTasbihHistory> {
  @override
  final typeId = 41;

  @override
  MTasbihHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MTasbihHistory(
      id: fields[0] as String,
      zekrAr: fields[1] as String,
      count: (fields[2] as num).toInt(),
      completedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MTasbihHistory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.zekrAr)
      ..writeByte(2)
      ..write(obj.count)
      ..writeByte(3)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MTasbihHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
