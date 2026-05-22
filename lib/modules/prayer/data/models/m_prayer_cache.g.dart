// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_prayer_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MPrayerCacheAdapter extends TypeAdapter<MPrayerCache> {
  @override
  final typeId = 21;

  @override
  MPrayerCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MPrayerCache(
      latitude: (fields[0] as num).toDouble(),
      longitude: (fields[1] as num).toDouble(),
      cityName: fields[2] as String,
      fajrIso: fields[3] as String,
      sunriseIso: fields[4] as String,
      dhuhrIso: fields[5] as String,
      asrIso: fields[6] as String,
      maghribIso: fields[7] as String,
      ishaIso: fields[8] as String,
      computedAtIso: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MPrayerCache obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.cityName)
      ..writeByte(3)
      ..write(obj.fajrIso)
      ..writeByte(4)
      ..write(obj.sunriseIso)
      ..writeByte(5)
      ..write(obj.dhuhrIso)
      ..writeByte(6)
      ..write(obj.asrIso)
      ..writeByte(7)
      ..write(obj.maghribIso)
      ..writeByte(8)
      ..write(obj.ishaIso)
      ..writeByte(9)
      ..write(obj.computedAtIso);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MPrayerCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
