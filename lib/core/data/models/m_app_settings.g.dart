// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MAppSettingsAdapter extends TypeAdapter<MAppSettings> {
  @override
  final typeId = 2;

  @override
  MAppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MAppSettings(
      hasSeenOnboarding: fields[0] == null ? false : fields[0] as bool,
      lastLanguageCode: fields[1] as String?,
      hasGrantedLocation: fields[2] == null ? false : fields[2] as bool,
      initNotificationsScheduled: fields[3] == null ? false : fields[3] as bool,
      hourlyTasbihSeeded: fields[4] == null ? false : fields[4] as bool,
      // Absent on every record predating the configurable window — those
      // decode to 08:00–22:00, exactly the window they already had.
      reminderWindowStartHour: fields[5] == null
          ? 8
          : (fields[5] as num).toInt(),
      reminderWindowEndHour: fields[6] == null
          ? 22
          : (fields[6] as num).toInt(),
      salawatIgnoreSilent: fields[7] == null ? false : fields[7] as bool,
      salawatPauseOnCall: fields[8] == null ? true : fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MAppSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.hasSeenOnboarding)
      ..writeByte(1)
      ..write(obj.lastLanguageCode)
      ..writeByte(2)
      ..write(obj.hasGrantedLocation)
      ..writeByte(3)
      ..write(obj.initNotificationsScheduled)
      ..writeByte(4)
      ..write(obj.hourlyTasbihSeeded)
      ..writeByte(5)
      ..write(obj.reminderWindowStartHour)
      ..writeByte(6)
      ..write(obj.reminderWindowEndHour)
      ..writeByte(7)
      ..write(obj.salawatIgnoreSilent)
      ..writeByte(8)
      ..write(obj.salawatPauseOnCall);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MAppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
