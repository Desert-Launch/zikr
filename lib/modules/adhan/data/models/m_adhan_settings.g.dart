// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_adhan_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MAdhanSettingsAdapter extends TypeAdapter<MAdhanSettings> {
  @override
  final typeId = 111;

  @override
  MAdhanSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MAdhanSettings(
      enabled: fields[0] == null ? true : fields[0] as bool,
      playbackMode: fields[1] == null ? 'clip' : fields[1] as String,
      androidBackgroundFullAdhan: fields[2] == null ? false : fields[2] as bool,
      vibrate: fields[3] == null ? true : fields[3] as bool,
      preNotifyMinutes: fields[4] == null ? 0 : (fields[4] as num).toInt(),
      bootstrapped: fields[5] == null ? false : fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MAdhanSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.playbackMode)
      ..writeByte(2)
      ..write(obj.androidBackgroundFullAdhan)
      ..writeByte(3)
      ..write(obj.vibrate)
      ..writeByte(4)
      ..write(obj.preNotifyMinutes)
      ..writeByte(5)
      ..write(obj.bootstrapped);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MAdhanSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
