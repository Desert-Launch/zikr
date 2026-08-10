import 'package:equatable/equatable.dart';
import 'package:quran/modules/prayer/domain/entities/e_location_failure.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';

enum PrayerLoadStatus { idle, loading, success, error, permissionDenied }

class SPrayerTimes extends Equatable {
  const SPrayerTimes({
    this.status = PrayerLoadStatus.idle,
    this.slots = const [],
    this.tomorrowSlots = const [],
    this.cityName = '',
    this.latitude,
    this.longitude,
    this.computedAt,
    this.error,
    this.locationFailure,
  });

  final PrayerLoadStatus status;

  /// Today's six timings, in order (fajr → isha).
  final List<PrayerSlot> slots;

  /// Tomorrow's six timings. Empty until [CBPrayerTimes] has resolved them;
  /// [nextDaySlots] covers that gap.
  final List<PrayerSlot> tomorrowSlots;

  final String cityName;
  final double? latitude;
  final double? longitude;
  final DateTime? computedAt;

  /// Untranslated diagnostic detail, for logs. NOT for the screen — it is
  /// whatever the failing layer happened to say, in English.
  final String? error;

  /// Why the location lookup failed, when it did. This is what the screen
  /// renders (translated) and what decides whether retrying can re-ask for the
  /// permission or has to open a settings page.
  final ELocationFailure? locationFailure;

  /// Tomorrow's timings — exact once fetched, otherwise today's shifted by a
  /// day.
  ///
  /// The shift is an approximation: real timings drift by about a minute a day.
  /// It exists only so the card has something honest to show in the seconds
  /// before the real fetch lands (or while offline) — the alternative was
  /// falling back to the clock, which read as a prayer time but wasn't one.
  List<PrayerSlot> get nextDaySlots {
    if (tomorrowSlots.isNotEmpty) return tomorrowSlots;
    if (slots.isEmpty) return const [];
    return slots
        .map((s) => PrayerSlot(prayer: s.prayer, time: s.time.add(const Duration(days: 1))))
        .toList(growable: false);
  }

  /// Whether any salah is still ahead today (sunrise excluded — not prayed).
  bool get hasPrayerLeftToday {
    final now = DateTime.now();
    return slots.any((s) => s.prayer != EPrayer.sunrise && s.time.isAfter(now));
  }

  /// The six timings the UI should list: today's until the last salah has gone,
  /// then the following day's. Without this the card kept displaying a spent
  /// day.
  List<PrayerSlot> get displaySlots =>
      slots.isNotEmpty && !hasPrayerLeftToday ? nextDaySlots : slots;

  /// Whether [displaySlots] belongs to a later calendar day than today, i.e.
  /// whether the UI should caption itself "tomorrow".
  ///
  /// Deliberately derived from the dates rather than from "today's are spent".
  /// Left open across midnight, [slots] still holds the previous day and the
  /// roll-over list becomes the *current* day — captioning that "tomorrow"
  /// would be wrong, and it stays right until the next refresh replaces both.
  bool get isShowingNextDay {
    final shown = displaySlots;
    if (shown.isEmpty) return false;
    final day = shown.first.time;
    final now = DateTime.now();
    return DateTime(day.year, day.month, day.day)
        .isAfter(DateTime(now.year, now.month, now.day));
  }

  /// The next future prayer (sunrise excluded since you don't pray it). Rolls
  /// into tomorrow's fajr once today's isha has passed, so this is null only
  /// when there is no timing data at all.
  PrayerSlot? get nextPrayer {
    final now = DateTime.now();
    for (final s in slots) {
      if (s.prayer == EPrayer.sunrise) continue;
      if (s.time.isAfter(now)) return s;
    }
    for (final s in nextDaySlots) {
      if (s.prayer == EPrayer.sunrise) continue;
      if (s.time.isAfter(now)) return s;
    }
    return null;
  }

  /// Returns the salah whose window the user is currently inside (most-recent
  /// past salah). Null before fajr.
  PrayerSlot? get currentSalah {
    final now = DateTime.now();
    PrayerSlot? hit;
    for (final s in slots) {
      if (s.prayer == EPrayer.sunrise) continue;
      if (s.time.isBefore(now) || s.time.isAtSameMomentAs(now)) hit = s;
    }
    return hit;
  }

  SPrayerTimes copyWith({
    PrayerLoadStatus? status,
    List<PrayerSlot>? slots,
    List<PrayerSlot>? tomorrowSlots,
    String? cityName,
    double? latitude,
    double? longitude,
    DateTime? computedAt,
    String? error,
    bool clearError = false,
    ELocationFailure? locationFailure,
  }) {
    return SPrayerTimes(
      status: status ?? this.status,
      slots: slots ?? this.slots,
      tomorrowSlots: tomorrowSlots ?? this.tomorrowSlots,
      cityName: cityName ?? this.cityName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      computedAt: computedAt ?? this.computedAt,
      error: clearError ? null : (error ?? this.error),
      // Cleared alongside the error: it describes the same failed attempt, and
      // a stale reason would send the next retry to the wrong settings page.
      locationFailure: clearError
          ? null
          : (locationFailure ?? this.locationFailure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    slots,
    tomorrowSlots,
    cityName,
    latitude,
    longitude,
    computedAt,
    error,
    locationFailure,
  ];
}
