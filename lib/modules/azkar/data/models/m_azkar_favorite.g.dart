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
      categoryId: fields[2] as String?,
      categoryNameAr: fields[3] as String?,
      categoryNameEn: fields[4] as String?,
      itemIndex: (fields[5] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MAzkarFavorite obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.itemId)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.categoryNameAr)
      ..writeByte(4)
      ..write(obj.categoryNameEn)
      ..writeByte(5)
      ..write(obj.itemIndex);
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
