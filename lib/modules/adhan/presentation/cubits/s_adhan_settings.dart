import 'package:equatable/equatable.dart';

class SAdhanSettings extends Equatable {
  const SAdhanSettings({
    this.loading = true,
    this.enabled = true,
    this.notifyForPrayer = const [true, true, true, true, true],
    this.playbackMode = 'clip',
    this.androidBackgroundFullAdhan = false,
    this.vibrate = true,
    this.preNotifyMinutes = 0,
    this.selectedVoiceNameAr = '',
    this.voiceIdPerPrayer = const {},
    this.voiceNamePerPrayer = const {},
    this.hasPermission = true,
    this.needsDefaultDownload = false,
    this.pendingDownloadVoiceId,
    this.retryingDownload = false,
    this.error,
  });

  final bool loading;
  final bool enabled;

  /// fajr/dhuhr/asr/maghrib/isha order.
  final List<bool> notifyForPrayer;
  final String playbackMode; // 'clip' | 'full'
  final bool androidBackgroundFullAdhan;
  final bool vibrate;
  final int preNotifyMinutes;
  final String selectedVoiceNameAr;
  final Map<String, String> voiceIdPerPrayer;
  final Map<String, String> voiceNamePerPrayer;
  final bool hasPermission;

  /// True when the selected default voice is a downloadable (remote) voice
  /// whose full file hasn't been fetched yet — e.g. the first-launch download
  /// failed offline. Drives the retry prompt.
  final bool needsDefaultDownload;

  /// The voice id the retry prompt should (re)download. Null when nothing is
  /// pending.
  final String? pendingDownloadVoiceId;

  /// True while a retry download is in flight (shows a spinner in the prompt).
  final bool retryingDownload;
  final String? error;

  SAdhanSettings copyWith({
    bool? loading,
    bool? enabled,
    List<bool>? notifyForPrayer,
    String? playbackMode,
    bool? androidBackgroundFullAdhan,
    bool? vibrate,
    int? preNotifyMinutes,
    String? selectedVoiceNameAr,
    Map<String, String>? voiceIdPerPrayer,
    Map<String, String>? voiceNamePerPrayer,
    bool? hasPermission,
    bool? needsDefaultDownload,
    String? pendingDownloadVoiceId,
    bool? retryingDownload,
    String? error,
    bool clearError = false,
  }) {
    return SAdhanSettings(
      loading: loading ?? this.loading,
      enabled: enabled ?? this.enabled,
      notifyForPrayer: notifyForPrayer ?? this.notifyForPrayer,
      playbackMode: playbackMode ?? this.playbackMode,
      androidBackgroundFullAdhan:
          androidBackgroundFullAdhan ?? this.androidBackgroundFullAdhan,
      vibrate: vibrate ?? this.vibrate,
      preNotifyMinutes: preNotifyMinutes ?? this.preNotifyMinutes,
      selectedVoiceNameAr: selectedVoiceNameAr ?? this.selectedVoiceNameAr,
      voiceIdPerPrayer: voiceIdPerPrayer ?? this.voiceIdPerPrayer,
      voiceNamePerPrayer: voiceNamePerPrayer ?? this.voiceNamePerPrayer,
      hasPermission: hasPermission ?? this.hasPermission,
      needsDefaultDownload:
          needsDefaultDownload ?? this.needsDefaultDownload,
      pendingDownloadVoiceId:
          pendingDownloadVoiceId ?? this.pendingDownloadVoiceId,
      retryingDownload: retryingDownload ?? this.retryingDownload,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    loading,
    enabled,
    notifyForPrayer,
    playbackMode,
    androidBackgroundFullAdhan,
    vibrate,
    preNotifyMinutes,
    selectedVoiceNameAr,
    voiceIdPerPrayer,
    voiceNamePerPrayer,
    hasPermission,
    needsDefaultDownload,
    pendingDownloadVoiceId,
    retryingDownload,
    error,
  ];
}
