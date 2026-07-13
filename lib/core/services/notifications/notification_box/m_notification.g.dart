// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'm_notification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MLocalNotificationAdapter extends TypeAdapter<MLocalNotification> {
  @override
  final typeId = 100;

  @override
  MLocalNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MLocalNotification(
      id: (fields[0] as num).toInt(),
      title: fields[1] as String,
      body: fields[2] as String,
      scheduledAt: fields[3] as DateTime,
      channelId: fields[4] as String,
      repeatDaily: fields[5] == null ? false : fields[5] as bool,
      weekday: fields[6] == null ? 0 : (fields[6] as num).toInt(),
      payloadType: fields[7] == null ? '' : fields[7] as String,
      payloadJson: fields[8] == null ? '' : fields[8] as String,
      autoSchedule: fields[9] == null ? false : fields[9] as bool,
      isEnabled: fields[10] == null ? true : fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MLocalNotification obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.scheduledAt)
      ..writeByte(4)
      ..write(obj.channelId)
      ..writeByte(5)
      ..write(obj.repeatDaily)
      ..writeByte(6)
      ..write(obj.weekday)
      ..writeByte(7)
      ..write(obj.payloadType)
      ..writeByte(8)
      ..write(obj.payloadJson)
      ..writeByte(9)
      ..write(obj.autoSchedule)
      ..writeByte(10)
      ..write(obj.isEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MLocalNotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
