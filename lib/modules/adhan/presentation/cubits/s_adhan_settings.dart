import 'package:equatable/equatable.dart';

class SAdhanSettings extends Equatable {
  const SAdhanSettings({
    this.loading = true,
    this.enabled = true,
    this.notifyForPrayer = const [true, true, true, true, true],
    this.playbackMode = 'clip',
    this.androidBackgroundFullAdhan = false,
    this.vibrate = true,
    this.preNotifyMinutesPerPrayer = const {},
    this.selectedVoiceNameAr = '',
    this.voiceIdPerPrayer = const {},
    this.voiceNamePerPrayer = const {},
    this.hasPermission = true,
    this.needsDefaultDownload = false,
    this.pendingDownloadVoiceId,
    this.retryingDownload = false,
    this.showBatteryNote = false,
    this.error,
  });

  final bool loading;
  final bool enabled;

  /// fajr/dhuhr/asr/maghrib/isha order.
  final List<bool> notifyForPrayer;
  final String playbackMode; // 'clip' | 'full'
  final bool androidBackgroundFullAdhan;
  final bool vibrate;

  /// Per-prayer pre-notify offset in minutes, keyed by prayer key. Missing
  /// key = off.
  final Map<String, int> preNotifyMinutesPerPrayer;
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

  /// True on Android when the app isn't exempt from battery optimization, so
  /// the OS may delay/kill exact alarms. Drives the battery guidance note.
  final bool showBatteryNote;
  final String? error;

  SAdhanSettings copyWith({
    bool? loading,
    bool? enabled,
    List<bool>? notifyForPrayer,
    String? playbackMode,
    bool? androidBackgroundFullAdhan,
    bool? vibrate,
    Map<String, int>? preNotifyMinutesPerPrayer,
    String? selectedVoiceNameAr,
    Map<String, String>? voiceIdPerPrayer,
    Map<String, String>? voiceNamePerPrayer,
    bool? hasPermission,
    bool? needsDefaultDownload,
    String? pendingDownloadVoiceId,
    bool? retryingDownload,
    bool? showBatteryNote,
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
      preNotifyMinutesPerPrayer:
          preNotifyMinutesPerPrayer ?? this.preNotifyMinutesPerPrayer,
      selectedVoiceNameAr: selectedVoiceNameAr ?? this.selectedVoiceNameAr,
      voiceIdPerPrayer: voiceIdPerPrayer ?? this.voiceIdPerPrayer,
      voiceNamePerPrayer: voiceNamePerPrayer ?? this.voiceNamePerPrayer,
      hasPermission: hasPermission ?? this.hasPermission,
      needsDefaultDownload:
          needsDefaultDownload ?? this.needsDefaultDownload,
      pendingDownloadVoiceId:
          pendingDownloadVoiceId ?? this.pendingDownloadVoiceId,
      retryingDownload: retryingDownload ?? this.retryingDownload,
      showBatteryNote: showBatteryNote ?? this.showBatteryNote,
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
    preNotifyMinutesPerPrayer,
    selectedVoiceNameAr,
    voiceIdPerPrayer,
    voiceNamePerPrayer,
    hasPermission,
    needsDefaultDownload,
    pendingDownloadVoiceId,
    retryingDownload,
    showBatteryNote,
    error,
  ];
}
