// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_khatma_completion.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MKhatmaCompletionAdapter extends TypeAdapter<MKhatmaCompletion> {
  @override
  final typeId = 83;

  @override
  MKhatmaCompletion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MKhatmaCompletion(
      id: fields[0] as String,
      planTotalDays: (fields[1] as num).toInt(),
      startedAt: fields[2] as DateTime,
      completedAt: fields[3] as DateTime,
      daysCompleted: (fields[4] as num).toInt(),
      longestStreakDays: (fields[5] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MKhatmaCompletion obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.planTotalDays)
      ..writeByte(2)
      ..write(obj.startedAt)
      ..writeByte(3)
      ..write(obj.completedAt)
      ..writeByte(4)
      ..write(obj.daysCompleted)
      ..writeByte(5)
      ..write(obj.longestStreakDays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MKhatmaCompletionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
