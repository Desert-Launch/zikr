// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_download_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MDownloadTaskAdapter extends TypeAdapter<MDownloadTask> {
  @override
  final typeId = 12;

  @override
  MDownloadTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MDownloadTask(
      id: fields[0] as String,
      reciterId: fields[1] as String,
      type: fields[2] as String,
      number: (fields[3] as num).toInt(),
      totalAyat: (fields[4] as num).toInt(),
      downloadedAyat: (fields[5] as num).toInt(),
      status: fields[6] as String,
      sizeBytes: (fields[7] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MDownloadTask obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.reciterId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.number)
      ..writeByte(4)
      ..write(obj.totalAyat)
      ..writeByte(5)
      ..write(obj.downloadedAyat)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.sizeBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MDownloadTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
