import 'package:quran/modules/prayer/domain/entities/e_daily_prayer_times.dart';
import 'package:quran/modules/prayer/domain/entities/e_next_prayer.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';

/// Resolves which salah is next, and which window the user is currently inside.
///
/// Pure — no repository, no clock of its own, no I/O. Every input is passed in,
/// which is what makes "after Isha it must be tomorrow's Fajr", the midnight
/// boundary and the DST cases testable without a device.
///
/// It works over a *list of days* rather than one, precisely so the roll-over
/// past Isha is a real lookup into tomorrow instead of today's Fajr shifted by
/// 24 hours. Sunrise is skipped throughout: it is listed on the screen but it
/// is not a prayer, and treating it as one puts a countdown on something nobody
/// prays.
///
/// Every time compared here is an absolute instant carrying the location's
/// zone, so a DST jump or a device on the wrong timezone changes nothing about
/// which comparison wins.
class UCGetNextPrayer {
  const UCGetNextPrayer();

  /// The first salah strictly after [now] across [days] (which should be
  /// today's timings followed by the days after it, in order).
  ///
  /// Null only when [days] holds no salah after [now] at all — i.e. there is
  /// no data, or the caller passed a window that has entirely elapsed.
  ENextPrayer? call({required List<EDailyPrayerTimes> days, DateTime? now}) {
    final moment = now ?? DateTime.now();
    for (final slot in _salahSlots(days)) {
      if (slot.time.isAfter(moment)) {
        return ENextPrayer(prayer: slot.prayer, time: slot.time);
      }
    }
    return null;
  }

  /// The most recent salah at or before [now] — the window the user is inside,
  /// and where a "time until the next prayer" bar starts filling.
  ///
  /// Null before the earliest Fajr in [days]; callers that need an anchor there
  /// should include the previous day in [days] rather than approximating one.
  PrayerSlot? currentSalah({
    required List<EDailyPrayerTimes> days,
    DateTime? now,
  }) {
    final moment = now ?? DateTime.now();
    PrayerSlot? hit;
    for (final slot in _salahSlots(days)) {
      if (slot.time.isAfter(moment)) break;
      hit = slot;
    }
    return hit;
  }

  /// Every salah across [days], flattened in clock order.
  ///
  /// [EDailyPrayerTimes.salahSlots] is already ordered within a day, and the
  /// days arrive in order, so no sort is needed — and none is wanted: a sort
  /// would quietly paper over a caller passing days out of order instead of
  /// letting that surface.
  Iterable<PrayerSlot> _salahSlots(List<EDailyPrayerTimes> days) sync* {
    for (final day in days) {
      yield* day.salahSlots;
    }
  }
}
