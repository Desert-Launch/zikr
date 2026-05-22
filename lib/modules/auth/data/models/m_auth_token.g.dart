// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_auth_token.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MAuthTokenAdapter extends TypeAdapter<MAuthToken> {
  @override
  final typeId = 1;

  @override
  MAuthToken read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MAuthToken(
      accessToken: fields[0] as String,
      refreshToken: fields[1] as String,
      issuedAt: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MAuthToken obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.accessToken)
      ..writeByte(1)
      ..write(obj.refreshToken)
      ..writeByte(2)
      ..write(obj.issuedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MAuthTokenAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
