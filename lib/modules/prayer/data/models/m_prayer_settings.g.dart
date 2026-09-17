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
          ? const [true, true, true, true, true, false]
          : (fields[2] as List).cast<bool>(),
      adhanIdPerPrayer: (fields[3] as Map?)?.cast<String, String>(),
      fajrAdhanId: fields[4] as String?,
      preNotifyMinutesPerPrayer: (fields[5] as Map?)?.cast<String, int>(),
      calculationModeIndex: fields[6] == null
          ? 0
          : (fields[6] as num).toInt(),
      manualMethodId: (fields[7] as num?)?.toInt(),
      highLatitudeRuleIndex: fields[8] == null
          ? 0
          : (fields[8] as num).toInt(),
      tuneMinutes: (fields[9] as List?)?.map((e) => (e as num).toInt()).toList(),
      resolvedMethodId: (fields[10] as num?)?.toInt(),
      resolvedMethodName: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MPrayerSettings obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.calculationMethodIndex)
      ..writeByte(1)
      ..write(obj.madhabIndex)
      ..writeByte(2)
      ..write(obj.notifyForPrayer)
      ..writeByte(3)
      ..write(obj.adhanIdPerPrayer)
      ..writeByte(4)
      ..write(obj.fajrAdhanId)
      ..writeByte(5)
      ..write(obj.preNotifyMinutesPerPrayer)
      ..writeByte(6)
      ..write(obj.calculationModeIndex)
      ..writeByte(7)
      ..write(obj.manualMethodId)
      ..writeByte(8)
      ..write(obj.highLatitudeRuleIndex)
      ..writeByte(9)
      ..write(obj.tuneMinutes)
      ..writeByte(10)
      ..write(obj.resolvedMethodId)
      ..writeByte(11)
      ..write(obj.resolvedMethodName);
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
