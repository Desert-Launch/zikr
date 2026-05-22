// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_khatma_day.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MKhatmaDayAdapter extends TypeAdapter<MKhatmaDay> {
  @override
  final typeId = 82;

  @override
  MKhatmaDay read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MKhatmaDay(
      dateKey: fields[0] as String,
      dayIndex: (fields[1] as num).toInt(),
      targetPages: (fields[2] as num).toInt(),
      pagesRead: fields[3] == null ? 0 : (fields[3] as num).toInt(),
      completed: fields[4] == null ? false : fields[4] as bool,
      completedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MKhatmaDay obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.dayIndex)
      ..writeByte(2)
      ..write(obj.targetPages)
      ..writeByte(3)
      ..write(obj.pagesRead)
      ..writeByte(4)
      ..write(obj.completed)
      ..writeByte(5)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MKhatmaDayAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
