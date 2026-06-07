// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_reminder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MReminderAdapter extends TypeAdapter<MReminder> {
  @override
  final typeId = 50;

  @override
  MReminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MReminder(
      id: fields[0] as String,
      title: fields[1] as String,
      hour: (fields[3] as num).toInt(),
      minute: (fields[4] as num).toInt(),
      daysOfWeek: (fields[5] as List).cast<bool>(),
      body: fields[2] == null ? '' : fields[2] as String,
      enabled: fields[6] == null ? true : fields[6] as bool,
      iconId: fields[8] == null ? 2 : (fields[8] as num).toInt(),
      colorId: fields[9] == null ? 3 : (fields[9] as num).toInt(),
      createdAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MReminder obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.hour)
      ..writeByte(4)
      ..write(obj.minute)
      ..writeByte(5)
      ..write(obj.daysOfWeek)
      ..writeByte(6)
      ..write(obj.enabled)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.iconId)
      ..writeByte(9)
      ..write(obj.colorId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
