// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MUserAdapter extends TypeAdapter<MUser> {
  @override
  final typeId = 0;

  @override
  MUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MUser(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[3] as String,
      nameEn: fields[2] as String?,
      phone: fields[4] as String?,
      avatar: fields[5] as String?,
      isVerified: fields[6] == null ? false : fields[6] as bool,
      createdAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MUser obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.nameEn)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.avatar)
      ..writeByte(6)
      ..write(obj.isVerified)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
