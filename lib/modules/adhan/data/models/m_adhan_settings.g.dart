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
      playbackMode: fields[1] == null ? 'full' : fields[1] as String,
      androidBackgroundFullAdhan: fields[2] == null ? true : fields[2] as bool,
      // fields[3] was `vibrate` — read and discarded on legacy records.
      preNotifyMinutes: fields[4] == null ? 0 : (fields[4] as num).toInt(),
      bootstrapped: fields[5] == null ? false : fields[5] as bool,
      fullScreenAlarm: fields[6] == null ? true : fields[6] as bool,
      alarmDefaultsApplied: fields[7] == null ? false : fields[7] as bool,
      // Absent on every record written before field 8 existed (including the
      // ones written while vibration was removed outright) — those decode to
      // the off default rather than throwing.
      vibrate: fields[8] == null ? false : fields[8] as bool,
      adhanVolume: fields[9] == null ? 100 : (fields[9] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MAdhanSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.playbackMode)
      ..writeByte(2)
      ..write(obj.androidBackgroundFullAdhan)
      ..writeByte(4)
      ..write(obj.preNotifyMinutes)
      ..writeByte(5)
      ..write(obj.bootstrapped)
      ..writeByte(6)
      ..write(obj.fullScreenAlarm)
      ..writeByte(7)
      ..write(obj.alarmDefaultsApplied)
      ..writeByte(8)
      ..write(obj.vibrate)
      ..writeByte(9)
      ..write(obj.adhanVolume);
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
