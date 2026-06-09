import 'package:hive_ce/hive.dart';
import 'package:quran/core/services/storage/hive_type_ids.dart';

part 'm_adhan_download.g.dart';

/// Per-voice download record. Keyed by voice id in `BoxAdhanDownload`. Tracks
/// where the downloaded full adhan lives so Tier-2 playback can resolve it.
@HiveType(typeId: HiveTypeIds.adhanDownload)
class MAdhanDownload extends HiveObject {
  MAdhanDownload({
    required this.voiceId,
    this.fullUrl,
    this.localPath,
    this.downloaded = false,
    this.sizeBytes = 0,
  });

  @HiveField(0)
  String voiceId;

  @HiveField(1)
  String? fullUrl;

  /// Absolute path on disk once the download succeeds.
  @HiveField(2)
  String? localPath;

  @HiveField(3)
  bool downloaded;

  @HiveField(4)
  int sizeBytes;
}
