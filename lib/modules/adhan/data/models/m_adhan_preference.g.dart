// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_adhan_preference.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MAdhanPreferenceAdapter extends TypeAdapter<MAdhanPreference> {
  @override
  final typeId = 110;

  @override
  MAdhanPreference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MAdhanPreference(
      defaultAdhanId: fields[0] as String?,
      fajrAdhanId: fields[1] as String?,
      useFajrSpecific: fields[2] == null ? true : fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MAdhanPreference obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.defaultAdhanId)
      ..writeByte(1)
      ..write(obj.fajrAdhanId)
      ..writeByte(2)
      ..write(obj.useFajrSpecific);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MAdhanPreferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
