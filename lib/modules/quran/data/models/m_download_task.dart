import 'package:hive_ce/hive.dart';

part 'm_download_task.g.dart';

@HiveType(typeId: 12)
class MDownloadTask extends HiveObject {
  MDownloadTask({
    required this.id,
    required this.reciterId,
    required this.type,
    required this.number,
    required this.totalAyat,
    required this.downloadedAyat,
    required this.status,
    required this.sizeBytes,
  });

  @HiveField(0)
  String id;

  /// E.g. "alafasy".
  @HiveField(1)
  String reciterId;

  /// 'surah' | 'juz'.
  @HiveField(2)
  String type;

  /// surah number 1..114 or juz number 1..30.
  @HiveField(3)
  int number;

  @HiveField(4)
  int totalAyat;

  @HiveField(5)
  int downloadedAyat;

  /// 'queued' | 'downloading' | 'paused' | 'done' | 'failed'.
  @HiveField(6)
  String status;

  @HiveField(7)
  int sizeBytes;

  double get progress => totalAyat == 0 ? 0 : downloadedAyat / totalAyat;
  bool get isDone => status == 'done';
  bool get isFailed => status == 'failed';
  bool get isActive => status == 'queued' || status == 'downloading';
}
