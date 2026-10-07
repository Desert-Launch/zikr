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
    final reminderWindowStartHour = fields[5] == null
        ? 8
        : (fields[5] as num).toInt();
    final reminderWindowEndHour = fields[6] == null
        ? 22
        : (fields[6] as num).toInt();
    return MAppSettings(
      hasSeenOnboarding: fields[0] == null ? false : fields[0] as bool,
      lastLanguageCode: fields[1] as String?,
      hasGrantedLocation: fields[2] == null ? false : fields[2] as bool,
      initNotificationsScheduled: fields[3] == null ? false : fields[3] as bool,
      hourlyTasbihSeeded: fields[4] == null ? false : fields[4] as bool,
      // Absent on every record predating the configurable window — those
      // decode to 08:00–22:00, exactly the window they already had.
      reminderWindowStartHour: reminderWindowStartHour,
      reminderWindowEndHour: reminderWindowEndHour,
      salawatIgnoreSilent: fields[7] == null ? false : fields[7] as bool,
      salawatPauseOnCall: fields[8] == null ? true : fields[8] as bool,
      // Absent on every record predating the per-zekr audio — those decode to
      // `true`, matching a fresh install. Nothing changes for them until the
      // clips are actually bundled; see `DSHourlyTasbih`.
      hourlyZikrSound: fields[9] == null ? true : fields[9] as bool,
      // Absent on every record predating the reminder volume settings.
      salawatVolume: fields[10] == null
          ? MAppSettings.defaultReminderVolume
          : (fields[10] as num).toInt(),
      hourlyZikrVolume: fields[11] == null
          ? MAppSettings.defaultReminderVolume
          : (fields[11] as num).toInt(),
      // Absent on every record from when the hourly zekr shared the salawat
      // window — those inherit that window, so the hours don't move on upgrade.
      hourlyWindowStartHour: fields[12] == null
          ? reminderWindowStartHour
          : (fields[12] as num).toInt(),
      hourlyWindowEndHour: fields[13] == null
          ? reminderWindowEndHour
          : (fields[13] as num).toInt(),
      hourlyRotationAnchorDay: fields[14] == null
          ? 0
          : (fields[14] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MAppSettings obj) {
    writer
      ..writeByte(15)
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
      ..write(obj.salawatPauseOnCall)
      ..writeByte(9)
      ..write(obj.hourlyZikrSound)
      ..writeByte(10)
      ..write(obj.salawatVolume)
      ..writeByte(11)
      ..write(obj.hourlyZikrVolume)
      ..writeByte(12)
      ..write(obj.hourlyWindowStartHour)
      ..writeByte(13)
      ..write(obj.hourlyWindowEndHour)
      ..writeByte(14)
      ..write(obj.hourlyRotationAnchorDay);
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
