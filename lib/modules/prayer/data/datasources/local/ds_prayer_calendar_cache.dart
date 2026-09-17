import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:quran/modules/prayer/data/models/m_prayer_calendar_cache.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_calendar.dart';

/// The app's monthly prayer-times cache — one JSON entry per
/// month + settings combination, in a plain `Box<String>`.
///
/// This is what stops the API being called on every home-screen open, and what
/// keeps prayer times on screen with no connection at all. The current and
/// next month are kept, so a month boundary never lands the user on an empty
/// screen either.
///
/// Lets exceptions bubble (data-source convention); a *corrupt* entry is not
/// an exception, it is a miss.
class DSPrayerCalendarCache {
  DSPrayerCalendarCache();

  static const String boxName = 'prayer_calendar_cache';

  Box<String> get _box => Hive.box<String>(boxName);

  /// The cached month for these settings, or null on a miss.
  ///
  /// Location is deliberately not part of the lookup: the caller compares the
  /// stored coordinates against where the user is now, because travel is a
  /// distance threshold, not an equality check.
  EPrayerCalendar? read({
    required int year,
    required int month,
    required String settingsSignature,
  }) => MPrayerCalendarCache.decode(
    _box.get(
      MPrayerCalendarCache.keyFor(
        year: year,
        month: month,
        settingsSignature: settingsSignature,
      ),
    ),
  );

  Future<void> write(EPrayerCalendar calendar) async {
    await _box.put(
      MPrayerCalendarCache.keyFor(
        year: calendar.year,
        month: calendar.month,
        settingsSignature: calendar.settingsSignature,
      ),
      MPrayerCalendarCache.encode(calendar),
    );
    await _prune();
  }

  /// Drops every month that ended before the previous one.
  ///
  /// The previous month is kept on purpose: just after midnight on the 1st,
  /// "yesterday" is still needed to anchor the countdown window that began
  /// with last night's Isha.
  ///
  /// Entries written under a settings signature the user has since changed
  /// away from age out through the same rule rather than being hunted down —
  /// they cost a few kilobytes for at most a month, and keeping them means
  /// flipping a setting back is instant and works offline.
  Future<void> _prune({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final cutoff = DateTime(today.year, today.month - 1);
    final stale = <dynamic>[];
    for (final key in _box.keys) {
      final month = _monthFromKey(key.toString());
      if (month != null && month.isBefore(cutoff)) stale.add(key);
    }
    if (stale.isNotEmpty) await _box.deleteAll(stale);
  }

  /// `2026-9#sig` → 1 September 2026.
  DateTime? _monthFromKey(String key) {
    final parts = key.split('#').first.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return null;
    return DateTime(year, month);
  }
}
