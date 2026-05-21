// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_reciter_pref.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MReciterPrefAdapter extends TypeAdapter<MReciterPref> {
  @override
  final typeId = 13;

  @override
  MReciterPref read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MReciterPref(
      activeReciterId: fields[0] as String,
      lastChangedAt: fields[1] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MReciterPref obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.activeReciterId)
      ..writeByte(1)
      ..write(obj.lastChangedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MReciterPrefAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
