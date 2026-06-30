import 'package:equatable/equatable.dart';

class STasbih extends Equatable {
  const STasbih({
    this.zekrAr = 'سُبْحَانَ اللَّهِ',
    this.target = 33,
    this.count = 0,
    this.vibrate = true,
    this.hourlyEnabled = false,
    this.reminderEnabled = false,
    this.reminderIntervalHours = 2,
    this.reminderHour = 9,
    this.reminderMinute = 30,
  });

  final String zekrAr;
  final int target;
  final int count;
  final bool vibrate;
  final bool hourlyEnabled;

  /// Salawat reminder settings (used by the salawat screen only).
  final bool reminderEnabled;

  /// Hours between reminders (08:30–22:30). `0` means a single daily reminder
  /// at [reminderHour]:[reminderMinute].
  final int reminderIntervalHours;
  final int reminderHour;
  final int reminderMinute;

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
    bool? reminderEnabled,
    int? reminderIntervalHours,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return STasbih(
      zekrAr: zekrAr ?? this.zekrAr,
      target: target ?? this.target,
      count: count ?? this.count,
      vibrate: vibrate ?? this.vibrate,
      hourlyEnabled: hourlyEnabled ?? this.hourlyEnabled,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderIntervalHours:
          reminderIntervalHours ?? this.reminderIntervalHours,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  @override
  List<Object?> get props => [
        zekrAr,
        target,
        count,
        vibrate,
        hourlyEnabled,
        reminderEnabled,
        reminderIntervalHours,
        reminderHour,
        reminderMinute,
      ];
}
