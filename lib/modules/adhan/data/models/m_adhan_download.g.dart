// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_adhan_download.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MAdhanDownloadAdapter extends TypeAdapter<MAdhanDownload> {
  @override
  final typeId = 112;

  @override
  MAdhanDownload read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MAdhanDownload(
      voiceId: fields[0] as String,
      fullUrl: fields[1] as String?,
      localPath: fields[2] as String?,
      downloaded: fields[3] == null ? false : fields[3] as bool,
      sizeBytes: fields[4] == null ? 0 : (fields[4] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MAdhanDownload obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.voiceId)
      ..writeByte(1)
      ..write(obj.fullUrl)
      ..writeByte(2)
      ..write(obj.localPath)
      ..writeByte(3)
      ..write(obj.downloaded)
      ..writeByte(4)
      ..write(obj.sizeBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MAdhanDownloadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
