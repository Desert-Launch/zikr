// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_bookmark.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MBookmarkAdapter extends TypeAdapter<MBookmark> {
  @override
  final typeId = 10;

  @override
  MBookmark read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MBookmark(
      id: fields[0] as String,
      surah: (fields[1] as num).toInt(),
      ayah: (fields[2] as num).toInt(),
      createdAt: fields[5] as DateTime,
      note: fields[3] as String?,
      folder: fields[4] as String?,
      colorHex: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MBookmark obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.surah)
      ..writeByte(2)
      ..write(obj.ayah)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.folder)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.colorHex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MBookmarkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
