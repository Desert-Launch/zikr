import 'package:equatable/equatable.dart';

/// Coarse download state of a single surah, derived purely from disk.
enum ESurahDownloadStatus { none, partial, complete }

/// Disk-truth snapshot for one surah: how many ayat are on disk vs the total.
///
/// Status is *computed* from [downloaded] / [total] — there is no persisted
/// flag, so it can never drift from the filesystem.
class SurahDownloadInfo extends Equatable {
  const SurahDownloadInfo({
    required this.surahNumber,
    required this.downloaded,
    required this.total,
  });

  final int surahNumber;
  final int downloaded;
  final int total;

  ESurahDownloadStatus get status {
    if (downloaded <= 0) return ESurahDownloadStatus.none;
    if (downloaded >= total) return ESurahDownloadStatus.complete;
    return ESurahDownloadStatus.partial;
  }

  double get fraction => total <= 0 ? 0 : (downloaded / total).clamp(0.0, 1.0);
  bool get isComplete => status == ESurahDownloadStatus.complete;

  @override
  List<Object?> get props => [surahNumber, downloaded, total];
}
