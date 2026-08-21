import 'package:quran/core/utils/hive_box_base.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_audio_download.dart';

/// Persisted download table for adhkar audio, keyed by `MAzkarAudio.id`.
///
/// Survives app restart, force-close and reboot, so a half-finished pack picks
/// up where it left off instead of starting over.
class BoxAzkarAudioDownload extends HiveBoxBase<MAzkarAudioDownload> {
  BoxAzkarAudioDownload() : super(boxName_);

  static const String boxName_ = 'azkar_audio_downloads';

  MAzkarAudioDownload? byId(String audioId) => box.get(audioId);

  bool isDownloaded(String audioId) => box.get(audioId)?.isDownloaded ?? false;

  /// Local path of a *completed* download, or null.
  String? localPath(String audioId) {
    final record = box.get(audioId);
    return (record?.isDownloaded ?? false) ? record?.localPath : null;
  }

  Future<void> save(MAzkarAudioDownload record) async {
    record.updatedAt = DateTime.now();
    await box.put(record.audioId, record);
  }

  Future<void> remove(String audioId) => box.delete(audioId);

  List<MAzkarAudioDownload> all() => box.values.toList(growable: false);

  List<MAzkarAudioDownload> forReader(String readerId) =>
      box.values.where((r) => r.readerId == readerId).toList(growable: false);

  /// Completed downloads for a reader, as `audioId`s — the cheap membership set
  /// the resolver and the counts both read.
  Set<String> downloadedIdsFor(String readerId) => box.values
      .where((r) => r.readerId == readerId && r.isDownloaded)
      .map((r) => r.audioId)
      .toSet();

  Set<String> get allDownloadedIds =>
      box.values.where((r) => r.isDownloaded).map((r) => r.audioId).toSet();

  int bytesFor(String readerId) => box.values
      .where((r) => r.readerId == readerId && r.isDownloaded)
      .fold<int>(0, (sum, r) => sum + r.bytesDownloaded);

  Future<void> removeReader(String readerId) async {
    final keys = box.values
        .where((r) => r.readerId == readerId)
        .map((r) => r.audioId)
        .toList(growable: false);
    await box.deleteAll(keys);
  }

  Future<void> clear() => box.clear();
}
