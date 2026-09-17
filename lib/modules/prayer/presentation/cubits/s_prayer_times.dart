import 'package:equatable/equatable.dart';
import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:quran/modules/prayer/domain/entities/e_location_failure.dart';
import 'package:quran/modules/prayer/domain/entities/e_next_prayer.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_schedule.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_source.dart';
import 'package:quran/modules/prayer/domain/usecases/uc_get_next_prayer.dart';

enum PrayerLoadStatus { idle, loading, success, error, permissionDenied }

/// Prayer-screen state.
///
/// It holds the [schedule] rather than a flat list of today's six timings, so
/// every derived question — what is next, which window we are in, whether the
/// card should have rolled into tomorrow — is answered from real days instead
/// of today's times shifted by 24 hours.
class SPrayerTimes extends Equatable {
  const SPrayerTimes({
    this.status = PrayerLoadStatus.idle,
    this.schedule,
    this.error,
    this.locationFailure,
  });

  final PrayerLoadStatus status;

  /// The resolved days, location, zone and authority. Null until the first
  /// successful load.
  final EPrayerSchedule? schedule;

  /// Untranslated diagnostic detail, for logs. NOT for the screen — it is
  /// whatever the failing layer happened to say, in English.
  final String? error;

  /// Why the location lookup failed, when it did. This is what the screen
  /// renders (translated) and what decides whether retrying can re-ask for the
  /// permission or has to open a settings page.
  final ELocationFailure? locationFailure;

  static const UCGetNextPrayer _nextPrayer = UCGetNextPrayer();

  String get cityName => schedule?.cityName ?? '';
  double? get latitude => schedule?.latitude;
  double? get longitude => schedule?.longitude;
  String get timezone => schedule?.timezone ?? '';
  DateTime? get computedAt => schedule?.fetchedAt;

  /// The authority the times were actually calculated with, for the "why do my
  /// times differ from the mosque" question.
  String get methodName => schedule?.methodName ?? '';

  /// Whether what is on screen is known to be behind — a cached month that
  /// could not be refreshed, or an on-device calculation. The screen shows a
  /// quiet marker; it never silently passes stale data off as live.
  bool get isStale => schedule?.source.isStale ?? false;

  EPrayerSource? get source => schedule?.source;

  bool get hasTimes => displaySlots.isNotEmpty;

  /// The day the screen lists: today until its last salah has gone, then the
  /// following day.
  EDailyPrayerTimes? get displayDay {
    final schedule = this.schedule;
    if (schedule == null) return null;
    final today = schedule.today();
    if (today == null) return schedule.days.isEmpty ? null : schedule.days.first;
    final now = DateTime.now();
    final hasPrayerLeft = today.salahSlots.any((s) => s.time.isAfter(now));
    return hasPrayerLeft ? today : (schedule.tomorrow() ?? today);
  }

  /// The six rows to list, in clock order. Empty when nothing has loaded.
  List<PrayerSlot> get displaySlots => displayDay?.slots ?? const [];

  /// Whether [displaySlots] belongs to a later calendar day than today, i.e.
  /// whether the UI should caption itself "tomorrow".
  bool get isShowingNextDay {
    final schedule = this.schedule;
    final shown = displayDay;
    if (schedule == null || shown == null) return false;
    return shown.date.isAfter(schedule.localDay());
  }

  /// The next salah — never sunrise, and tomorrow's Fajr once tonight's Isha
  /// has gone. Null only when there is no timing data at all.
  ENextPrayer? get nextPrayer {
    final schedule = this.schedule;
    if (schedule == null) return null;
    return _nextPrayer(days: schedule.fromToday());
  }

  /// Where the countdown bar for [nextPrayer] starts filling: the salah whose
  /// window the user is currently inside.
  ///
  /// Anchored on the previous salah rather than on midnight, so the fraction
  /// means "how much of THIS gap has elapsed" — anchored at midnight the bar
  /// read almost full the moment Isha ended, because most of the calendar day
  /// was gone even though none of the wait for Fajr was.
  ///
  /// Before today's Fajr the answer is last night's Isha, which is a real
  /// timing here: the schedule deliberately carries yesterday.
  DateTime? get currentWindowStart =>
      _nextPrayer.currentSalah(days: schedule?.days ?? const [])?.time;

  SPrayerTimes copyWith({
    PrayerLoadStatus? status,
    EPrayerSchedule? schedule,
    String? error,
    bool clearError = false,
    ELocationFailure? locationFailure,
  }) => SPrayerTimes(
    status: status ?? this.status,
    schedule: schedule ?? this.schedule,
    error: clearError ? null : (error ?? this.error),
    // Cleared alongside the error: it describes the same failed attempt, and
    // a stale reason would send the next retry to the wrong settings page.
    locationFailure: clearError
        ? null
        : (locationFailure ?? this.locationFailure),
  );

  @override
  List<Object?> get props => [status, schedule, error, locationFailure];
}
