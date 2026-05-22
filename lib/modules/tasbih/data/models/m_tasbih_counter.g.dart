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
    );
  }

  @override
  void write(BinaryWriter writer, MTasbihCounter obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.zekrAr)
      ..writeByte(1)
      ..write(obj.target)
      ..writeByte(2)
      ..write(obj.count)
      ..writeByte(3)
      ..write(obj.vibrate)
      ..writeByte(4)
      ..write(obj.hourlyEnabled);
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
