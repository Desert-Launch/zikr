// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_azkar_audio_download.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MAzkarAudioDownloadAdapter extends TypeAdapter<MAzkarAudioDownload> {
  @override
  final typeId = 32;

  @override
  MAzkarAudioDownload read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MAzkarAudioDownload(
      audioId: fields[0] as String,
      readerId: fields[1] as String,
      remoteUrl: fields[2] as String,
      adhkarId: fields[3] as String?,
      categoryIds: fields[4] == null
          ? const <String>[]
          : (fields[4] as List).cast<String>(),
      localPath: fields[5] as String?,
      bytesDownloaded: fields[6] == null ? 0 : (fields[6] as num).toInt(),
      totalBytes: fields[7] == null ? 0 : (fields[7] as num).toInt(),
      status: fields[8] == null
          ? MAzkarAudioDownload.statusPending
          : fields[8] as String,
      updatedAt: fields[9] as DateTime?,
      error: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MAzkarAudioDownload obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.audioId)
      ..writeByte(1)
      ..write(obj.readerId)
      ..writeByte(2)
      ..write(obj.remoteUrl)
      ..writeByte(3)
      ..write(obj.adhkarId)
      ..writeByte(4)
      ..write(obj.categoryIds)
      ..writeByte(5)
      ..write(obj.localPath)
      ..writeByte(6)
      ..write(obj.bytesDownloaded)
      ..writeByte(7)
      ..write(obj.totalBytes)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.error);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MAzkarAudioDownloadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
