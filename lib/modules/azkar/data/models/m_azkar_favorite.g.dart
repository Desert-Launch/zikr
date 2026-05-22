// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_azkar_favorite.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MAzkarFavoriteAdapter extends TypeAdapter<MAzkarFavorite> {
  @override
  final typeId = 30;

  @override
  MAzkarFavorite read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MAzkarFavorite(
      itemId: fields[0] as String,
      createdAt: fields[1] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MAzkarFavorite obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.itemId)
      ..writeByte(1)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MAzkarFavoriteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
