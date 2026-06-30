// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_tasbih_counter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MTasbihCounterAdapter extends TypeAdapter<MTasbihCounter> {
  @override
  final typeId = 40;

  @override
  MTasbihCounter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MTasbihCounter(
      zekrAr: fields[0] == null ? 'سُبْحَانَ اللَّهِ' : fields[0] as String,
      target: fields[1] == null ? 33 : (fields[1] as num).toInt(),
      count: fields[2] == null ? 0 : (fields[2] as num).toInt(),
      vibrate: fields[3] == null ? true : fields[3] as bool,
      hourlyEnabled: fields[4] == null ? false : fields[4] as bool,
      reminderEnabled: fields[5] == null ? false : fields[5] as bool,
      reminderIntervalHours: fields[6] == null ? 2 : (fields[6] as num).toInt(),
      reminderHour: fields[7] == null ? 9 : (fields[7] as num).toInt(),
      reminderMinute: fields[8] == null ? 30 : (fields[8] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MTasbihCounter obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.zekrAr)
      ..writeByte(1)
      ..write(obj.target)
      ..writeByte(2)
      ..write(obj.count)
      ..writeByte(3)
      ..write(obj.vibrate)
      ..writeByte(4)
      ..write(obj.hourlyEnabled)
      ..writeByte(5)
      ..write(obj.reminderEnabled)
      ..writeByte(6)
      ..write(obj.reminderIntervalHours)
      ..writeByte(7)
      ..write(obj.reminderHour)
      ..writeByte(8)
      ..write(obj.reminderMinute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MTasbihCounterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
