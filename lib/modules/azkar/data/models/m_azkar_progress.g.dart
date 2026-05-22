// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_azkar_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MAzkarProgressAdapter extends TypeAdapter<MAzkarProgress> {
  @override
  final typeId = 31;

  @override
  MAzkarProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MAzkarProgress(
      dayKey: fields[0] as String,
      completedCounts: (fields[1] as Map).cast<String, int>(),
      updatedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MAzkarProgress obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dayKey)
      ..writeByte(1)
      ..write(obj.completedCounts)
      ..writeByte(2)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MAzkarProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
