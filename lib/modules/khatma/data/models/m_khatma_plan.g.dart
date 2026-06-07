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
      planId: fields[3] == null ? 0 : (fields[3] as num).toInt(),
      currentWirdIndex: fields[4] == null ? 1 : (fields[4] as num).toInt(),
      reminderEnabled: fields[5] == null ? true : fields[5] as bool,
      reminderHour: fields[6] == null ? 8 : (fields[6] as num).toInt(),
      reminderMinute: fields[7] == null ? 0 : (fields[7] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MKhatmaPlan obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.totalDays)
      ..writeByte(1)
      ..write(obj.startedAt)
      ..writeByte(2)
      ..write(obj.isActive)
      ..writeByte(3)
      ..write(obj.planId)
      ..writeByte(4)
      ..write(obj.currentWirdIndex)
      ..writeByte(5)
      ..write(obj.reminderEnabled)
      ..writeByte(6)
      ..write(obj.reminderHour)
      ..writeByte(7)
      ..write(obj.reminderMinute);
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
