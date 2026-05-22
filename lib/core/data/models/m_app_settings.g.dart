// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MAppSettingsAdapter extends TypeAdapter<MAppSettings> {
  @override
  final typeId = 2;

  @override
  MAppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MAppSettings(
      hasSeenOnboarding: fields[0] == null ? false : fields[0] as bool,
      lastLanguageCode: fields[1] as String?,
      hasGrantedLocation: fields[2] == null ? false : fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MAppSettings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.hasSeenOnboarding)
      ..writeByte(1)
      ..write(obj.lastLanguageCode)
      ..writeByte(2)
      ..write(obj.hasGrantedLocation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MAppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
