// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_last_read.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MLastReadAdapter extends TypeAdapter<MLastRead> {
  @override
  final typeId = 11;

  @override
  MLastRead read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MLastRead(
      surah: (fields[0] as num).toInt(),
      ayah: (fields[1] as num).toInt(),
      page: (fields[2] as num).toInt(),
      updatedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MLastRead obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.surah)
      ..writeByte(1)
      ..write(obj.ayah)
      ..writeByte(2)
      ..write(obj.page)
      ..writeByte(3)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MLastReadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
