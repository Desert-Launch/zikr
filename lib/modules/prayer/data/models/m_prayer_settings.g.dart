// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_prayer_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MPrayerSettingsAdapter extends TypeAdapter<MPrayerSettings> {
  @override
  final typeId = 20;

  @override
  MPrayerSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MPrayerSettings(
      calculationMethodIndex: fields[0] == null
          ? 1
          : (fields[0] as num).toInt(),
      madhabIndex: fields[1] == null ? 0 : (fields[1] as num).toInt(),
      notifyForPrayer: fields[2] == null
          ? const [true, true, true, true, true]
          : (fields[2] as List).cast<bool>(),
      adhanIdPerPrayer: (fields[3] as Map?)?.cast<String, String>(),
      fajrAdhanId: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MPrayerSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.calculationMethodIndex)
      ..writeByte(1)
      ..write(obj.madhabIndex)
      ..writeByte(2)
      ..write(obj.notifyForPrayer)
      ..writeByte(3)
      ..write(obj.adhanIdPerPrayer)
      ..writeByte(4)
      ..write(obj.fajrAdhanId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MPrayerSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
