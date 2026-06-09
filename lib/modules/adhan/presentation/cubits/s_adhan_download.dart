import 'package:equatable/equatable.dart';

enum AdhanDownloadStatus { idle, downloading, success, failure }

/// Tracks a single in-flight (or last) voice download. The voice picker reads
/// [voiceId] + [progress] to render the right row's spinner/bar.
class SAdhanDownload extends Equatable {
  const SAdhanDownload({
    this.status = AdhanDownloadStatus.idle,
    this.voiceId,
    this.received = 0,
    this.total = 0,
    this.error,
  });

  final AdhanDownloadStatus status;
  final String? voiceId;
  final int received;
  final int total;
  final String? error;

  /// 0.0–1.0, or null when the total isn't known yet.
  double? get progress => total > 0 ? (received / total).clamp(0, 1) : null;

  SAdhanDownload copyWith({
    AdhanDownloadStatus? status,
    String? voiceId,
    int? received,
    int? total,
    String? error,
    bool clearError = false,
  }) {
    return SAdhanDownload(
      status: status ?? this.status,
      voiceId: voiceId ?? this.voiceId,
      received: received ?? this.received,
      total: total ?? this.total,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, voiceId, received, total, error];
}
