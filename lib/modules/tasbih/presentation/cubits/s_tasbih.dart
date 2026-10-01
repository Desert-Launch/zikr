import 'package:equatable/equatable.dart';
import 'package:quran/core/data/models/m_app_settings.dart';

class STasbih extends Equatable {
  const STasbih({
    this.zekrAr = 'سُبْحَانَ اللَّهِ',
    this.target = 33,
    this.count = 0,
    this.vibrate = true,
    this.hourlyEnabled = true,
    this.hourlyZikrSound = true,
    this.hourlyZikrVolume = MAppSettings.defaultReminderVolume,
    this.reminderEnabled = true,
    this.reminderIntervalHours = 3,
    this.reminderHour = 9,
    this.reminderMinute = 30,
    this.windowStartHour = 8,
    this.windowEndHour = 22,
    this.ignoreSilent = false,
    this.pauseOnCall = true,
    this.reminderVolume = MAppSettings.defaultReminderVolume,
    this.previewPlaying = false,
  });

  final String zekrAr;
  final int target;
  final int count;
  final bool vibrate;
  final bool hourlyEnabled;

  /// Read each hourly zekr aloud with its own clip, instead of leaving the
  /// reminder silent. See [MAppSettings.hourlyZikrSound].
  final bool hourlyZikrSound;

  /// Hourly zekr loudness, 0–100. See [MAppSettings.hourlyZikrVolume].
  final int hourlyZikrVolume;

  /// Salawat reminder settings (used by the salawat screen only).
  final bool reminderEnabled;

  /// Hours between reminders (08:00–22:00), 3 by default. `0` means a single
  /// daily reminder at [reminderHour]:[reminderMinute].
  final int reminderIntervalHours;
  final int reminderHour;
  final int reminderMinute;

  /// Reminder-window bounds (inclusive hours). Governs the salawat interval
  /// reminders and the hourly zekr — and nothing else. See
  /// [MAppSettings.reminderWindowStartHour].
  final int windowStartHour;
  final int windowEndHour;

  /// Sound the salawat reminder through silent/vibrate (Android-only effect).
  final bool ignoreSilent;

  /// Hold back app-played salawat feedback while a call/other app owns audio.
  final bool pauseOnCall;

  /// Salawat reminder loudness, 0–100. See [MAppSettings.salawatVolume].
  final int reminderVolume;

  /// The reminder clip is auditioning right now (settings sheet preview).
  /// Transient — never persisted.
  final bool previewPlaying;

  bool get isComplete => count >= target;
  double get progress => target == 0 ? 0.0 : (count / target).clamp(0.0, 1.0);

  /// True when the reminder uses a single specific time rather than an interval.
  bool get reminderIsSpecificTime => reminderIntervalHours == 0;

  STasbih copyWith({
    String? zekrAr,
    int? target,
    int? count,
    bool? vibrate,
    bool? hourlyEnabled,
    bool? hourlyZikrSound,
    int? hourlyZikrVolume,
    bool? reminderEnabled,
    int? reminderIntervalHours,
    int? reminderHour,
    int? reminderMinute,
    int? windowStartHour,
    int? windowEndHour,
    bool? ignoreSilent,
    bool? pauseOnCall,
    int? reminderVolume,
    bool? previewPlaying,
  }) {
    return STasbih(
      zekrAr: zekrAr ?? this.zekrAr,
      target: target ?? this.target,
      count: count ?? this.count,
      vibrate: vibrate ?? this.vibrate,
      hourlyEnabled: hourlyEnabled ?? this.hourlyEnabled,
      hourlyZikrSound: hourlyZikrSound ?? this.hourlyZikrSound,
      hourlyZikrVolume: hourlyZikrVolume ?? this.hourlyZikrVolume,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderIntervalHours:
          reminderIntervalHours ?? this.reminderIntervalHours,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      windowStartHour: windowStartHour ?? this.windowStartHour,
      windowEndHour: windowEndHour ?? this.windowEndHour,
      ignoreSilent: ignoreSilent ?? this.ignoreSilent,
      pauseOnCall: pauseOnCall ?? this.pauseOnCall,
      reminderVolume: reminderVolume ?? this.reminderVolume,
      previewPlaying: previewPlaying ?? this.previewPlaying,
    );
  }

  @override
  List<Object?> get props => [
    zekrAr,
    target,
    count,
    vibrate,
    hourlyEnabled,
    hourlyZikrSound,
    hourlyZikrVolume,
    reminderEnabled,
    reminderIntervalHours,
    reminderHour,
    reminderMinute,
    windowStartHour,
    windowEndHour,
    ignoreSilent,
    pauseOnCall,
    reminderVolume,
    previewPlaying,
  ];
}
