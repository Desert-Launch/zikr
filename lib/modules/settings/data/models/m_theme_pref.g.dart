// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_theme_pref.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MThemePrefAdapter extends TypeAdapter<MThemePref> {
  @override
  final typeId = 3;

  @override
  MThemePref read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MThemePref(modeIndex: (fields[0] as num).toInt());
  }

  @override
  void write(BinaryWriter writer, MThemePref obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.modeIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MThemePrefAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
