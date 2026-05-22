// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_khatma_plan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MKhatmaPlanAdapter extends TypeAdapter<MKhatmaPlan> {
  @override
  final typeId = 80;

  @override
  MKhatmaPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MKhatmaPlan(
      totalDays: (fields[0] as num).toInt(),
      startedAt: fields[1] as DateTime,
      isActive: fields[2] == null ? true : fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MKhatmaPlan obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.totalDays)
      ..writeByte(1)
      ..write(obj.startedAt)
      ..writeByte(2)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MKhatmaPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
