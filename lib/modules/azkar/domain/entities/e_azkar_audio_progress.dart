import 'package:equatable/equatable.dart';

/// What one reader's pack looks like on this device.
///
/// [downloaded] is reconciled against the filesystem, so it never claims files
/// the OS has since reclaimed.
class AzkarReaderStats extends Equatable {
  const AzkarReaderStats({
    required this.readerId,
    required this.downloaded,
    required this.total,
    required this.bytesOnDisk,
    required this.estimatedBytes,
    this.failed = 0,
  });

  const AzkarReaderStats.empty(this.readerId)
    : downloaded = 0,
      total = 0,
      bytesOnDisk = 0,
      estimatedBytes = 0,
      failed = 0;

  final String readerId;

  /// Files complete on disk.
  final int downloaded;

  /// Files this reader offers in total.
  final int total;

  /// Files whose last transfer failed and can be retried.
  final int failed;

  final int bytesOnDisk;

  /// Sum of the manifest's `fileSize` values — what a full download costs.
  final int estimatedBytes;

  bool get isEmpty => downloaded == 0;
  bool get isComplete => total > 0 && downloaded >= total;
  bool get isPartial => downloaded > 0 && !isComplete;

  double get fraction =>
      total <= 0 ? 0 : (downloaded / total).clamp(0.0, 1.0);

  double get megabytesOnDisk => bytesOnDisk / 1024 / 1024;
  double get estimatedMegabytes => estimatedBytes / 1024 / 1024;

  /// Bytes still to fetch, floored at zero.
  int get remainingBytes {
    final left = estimatedBytes - bytesOnDisk;
    return left < 0 ? 0 : left;
  }

  AzkarReaderStats copyWith({
    int? downloaded,
    int? total,
    int? failed,
    int? bytesOnDisk,
    int? estimatedBytes,
  }) {
    return AzkarReaderStats(
      readerId: readerId,
      downloaded: downloaded ?? this.downloaded,
      total: total ?? this.total,
      failed: failed ?? this.failed,
      bytesOnDisk: bytesOnDisk ?? this.bytesOnDisk,
      estimatedBytes: estimatedBytes ?? this.estimatedBytes,
    );
  }

  @override
  List<Object?> get props => [
    readerId,
    downloaded,
    total,
    failed,
    bytesOnDisk,
    estimatedBytes,
  ];
}

/// Live progress of a running pack download (a whole reader, or one category).
class AzkarPackProgress extends Equatable {
  const AzkarPackProgress({
    required this.readerId,
    required this.completed,
    required this.total,
    this.categoryId,
    this.failed = 0,
    this.currentBytes = 0,
    this.currentTotalBytes = 0,
    this.error,
    this.cancelled = false,
  });

  final String readerId;

  /// Set when only one category is being fetched.
  final String? categoryId;

  final int completed;
  final int total;
  final int failed;

  /// Byte progress of the file currently in flight.
  final int currentBytes;
  final int currentTotalBytes;

  final String? error;
  final bool cancelled;

  bool get isDone => cancelled || completed + failed >= total;

  double get fraction =>
      total <= 0 ? 1 : ((completed + failed) / total).clamp(0.0, 1.0);

  /// 0.0–1.0 for the file in flight, or null when its size is unknown.
  double? get currentFraction => currentTotalBytes > 0
      ? (currentBytes / currentTotalBytes).clamp(0.0, 1.0)
      : null;

  AzkarPackProgress copyWith({
    int? completed,
    int? total,
    int? failed,
    int? currentBytes,
    int? currentTotalBytes,
    String? error,
    bool? cancelled,
    bool clearError = false,
  }) {
    return AzkarPackProgress(
      readerId: readerId,
      categoryId: categoryId,
      completed: completed ?? this.completed,
      total: total ?? this.total,
      failed: failed ?? this.failed,
      currentBytes: currentBytes ?? this.currentBytes,
      currentTotalBytes: currentTotalBytes ?? this.currentTotalBytes,
      error: clearError ? null : (error ?? this.error),
      cancelled: cancelled ?? this.cancelled,
    );
  }

  @override
  List<Object?> get props => [
    readerId,
    categoryId,
    completed,
    total,
    failed,
    currentBytes,
    currentTotalBytes,
    error,
    cancelled,
  ];
}

/// One category's slice of a reader's pack, for the reader detail screen.
class AzkarCategoryAudioInfo extends Equatable {
  const AzkarCategoryAudioInfo({
    required this.categoryId,
    required this.nameAr,
    required this.nameEn,
    required this.downloaded,
    required this.total,
    required this.bytes,
    required this.hasCategoryRecording,
  });

  final String categoryId;
  final String nameAr;
  final String nameEn;
  final int downloaded;
  final int total;

  /// Estimated bytes for this category's files.
  final int bytes;

  /// Whether this slice includes a whole-sitting recording.
  final bool hasCategoryRecording;

  bool get isComplete => total > 0 && downloaded >= total;
  double get fraction => total <= 0 ? 0 : (downloaded / total).clamp(0.0, 1.0);

  String name(bool isArabic) => isArabic ? nameAr : (nameEn.isEmpty ? nameAr : nameEn);

  @override
  List<Object?> get props => [categoryId, downloaded, total, bytes];
}

/// Whole-library storage summary for the storage card.
class AzkarStorageUsage extends Equatable {
  const AzkarStorageUsage({required this.totalBytes, required this.perReader});

  const AzkarStorageUsage.empty()
    : totalBytes = 0,
      perReader = const <String, int>{};

  final int totalBytes;
  final Map<String, int> perReader;

  double get totalMegabytes => totalBytes / 1024 / 1024;
  bool get isEmpty => totalBytes <= 0;

  @override
  List<Object?> get props => [totalBytes, perReader];
}
