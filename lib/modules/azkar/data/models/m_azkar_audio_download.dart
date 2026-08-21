import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_azkar_audio_download.g.dart';

/// Persisted state of one audio file's download, keyed by `MAzkarAudio.id`.
///
/// This table is *not* the source of truth for "is it on disk" — the
/// filesystem is. It records what was attempted (bytes, total, status, where it
/// was written) so a download survives a restart and so a partial transfer can
/// resume with a `Range` request. Startup reconciliation walks these records
/// against real files and repairs any that disagree.
@HiveType(typeId: HiveTypeIds.azkarAudioDownload)
class MAzkarAudioDownload extends HiveObject {
  MAzkarAudioDownload({
    required this.audioId,
    required this.readerId,
    required this.remoteUrl,
    this.adhkarId,
    this.categoryIds = const <String>[],
    this.localPath,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.status = statusPending,
    this.updatedAt,
    this.error,
  });

  static const String statusPending = 'pending';
  static const String statusDownloading = 'downloading';
  static const String statusDownloaded = 'downloaded';
  static const String statusFailed = 'failed';

  @HiveField(0)
  String audioId;

  @HiveField(1)
  String readerId;

  @HiveField(2)
  String remoteUrl;

  @HiveField(3)
  String? adhkarId;

  @HiveField(4)
  List<String> categoryIds;

  @HiveField(5)
  String? localPath;

  @HiveField(6)
  int bytesDownloaded;

  @HiveField(7)
  int totalBytes;

  @HiveField(8)
  String status;

  @HiveField(9)
  DateTime? updatedAt;

  @HiveField(10)
  String? error;

  bool get isDownloaded => status == statusDownloaded;
  bool get isFailed => status == statusFailed;
}
