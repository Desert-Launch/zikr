import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/notification_channels.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
import 'package:quran/core/services/notifications/notification_slots.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_counter.dart';

/// Schedules the hourly zekr notifications (Decision 2). One per hour from
/// 08:00 to 22:00, silent + low importance — see [AppNotificationChannels.hourly].
///
/// Phrases are loaded from `assets/data/notifictaions/hourly_notifications.json`
/// (falling back to a hard-coded list), rotated with `hour % len`.
///
/// **Same-hour conflict avoidance:** other feeds (prayer, azkar/quran init)
/// also land on the hour boundary, so passing their [reservedTimes] shifts a
/// colliding hourly slot off `:00` to keep a 10-minute gap. Only the minute
/// changes — the id (`_baseId + hour`) stays stable so cancel/reschedule is
/// symmetric.
///
/// Notification IDs reserved: 5008..5022 (one per active hour, `_baseId + hour`).
class DSHourlyTasbih {
  DSHourlyTasbih(this._notifications, this._counter, this._appSettings);

  final NotificationsService _notifications;
  final BoxTasbihCounter _counter;
  final BoxAppSettings _appSettings;

  static const _assetPath =
      'assets/data/notifictaions/hourly_notifications.json';

  static const _baseId = 5000;
  static const _activeHours = [
    8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
  ];

  /// Preferred minutes, in order. `:00` first (the true "hourly" cadence);
  /// shift to `:10`/`:20`/`:50` etc. only when a reserved time collides. `:30`
  /// is last so we don't step on the salawat reminder (which fires at `:30`).
  static const _minuteCandidates = [0, 10, 20, 50, 40, 15, 45, 5, 25, 30];

  /// Fallback phrases — cycled with `hour % len` when the JSON can't be read.
  static const _phrases = [
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'لَا إِلَهَ إِلَّا اللَّهُ',
    'اللَّهُ أَكْبَرُ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'أَسْتَغْفِرُ اللَّهَ',
    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    'سُبْحَانَ اللَّهِ الْعَظِيمِ',
    'حَسْبِيَ اللَّهُ وَنِعْمَ الْوَكِيلُ',
  ];

  /// Cached `{ar, en}` phrase rows loaded from JSON (null until first load).
  List<Map<String, String>>? _azkar;

  /// Times claimed by the other feeds on the last coordinated run. Cached so a
  /// UI-triggered toggle (which carries no prayer-time context) still places
  /// the slots around the known prayer / azkar / salawat times.
  List<DateTime> _lastReserved = const [];

  /// (Re)schedules every active hour. [reservedTimes] are times already claimed
  /// by other feeds today; any hour that would collide is shifted off `:00`.
  /// Omit it to reuse the set from the last coordinated run.
  Future<void> enable({List<DateTime>? reservedTimes}) async {
    final reserved = reservedTimes ?? _lastReserved;
    _lastReserved = reserved;
    await _loadAzkar();
    // Each placed slot joins the reserved set so consecutive hours can't be
    // shifted onto each other (e.g. 12:50 and 13:00).
    final taken = NotificationSlots.minutesOfDay(reserved);
    for (final hour in _activeHours) {
      final minute = _minuteForHour(hour, taken);
      taken.add(hour * 60 + minute);
      await _notifications.scheduleDaily(
        id: _baseId + hour,
        hour: hour,
        minute: minute,
        title: 'تذكير الساعة',
        body: _bodyForHour(hour),
        channel: AppNotificationChannels.hourly,
        payload: const NotificationPayload(type: 'hourly'),
      );
    }
    AppLogger.info(
      'Hourly zekr scheduled (${_activeHours.length} slots, '
      '${reserved.length} reserved times)',
      tag: 'HourlyZekr',
    );
  }

  /// Recomputes the hourly schedule against a fresh [reservedTimes] set — call
  /// this once prayer + azkar times are known (from the adhan reschedule). No-op
  /// when the user has the hourly zekr turned off.
  Future<void> rescheduleWithReservedTimes(
    List<DateTime> reservedTimes,
  ) async {
    // Recorded even when the feature is off, so switching it on later from the
    // UI (which passes no reserved times) still lands on conflict-free slots.
    _lastReserved = reservedTimes;
    await seedDefaultIfNeeded();
    if (!_counter.current().hourlyEnabled) return;
    await enable(reservedTimes: reservedTimes);
  }

  /// Turns the hourly zekr on once, for installs carrying the old default.
  ///
  /// The feature shipped off by default, so `MTasbihCounter.hourlyEnabled` is
  /// already persisted as `false` on those devices — bumping the model default
  /// only reaches fresh installs. This writes the new default through on the
  /// first launch after the change and records
  /// [MAppSettings.hourlyTasbihSeeded], so a user who switches the reminder
  /// off afterwards is never flipped back on by a later boot.
  ///
  /// Runs on the boot reschedule path (before [CBTasbih] is ever constructed),
  /// so the settings switch reads the seeded value rather than a stale `false`.
  Future<void> seedDefaultIfNeeded() async {
    if (_appSettings.current().hourlyTasbihSeeded) return;
    final counter = _counter.current();
    if (!counter.hourlyEnabled) {
      counter.hourlyEnabled = true;
      await counter.save();
      AppLogger.info('Hourly zekr seeded on by default', tag: 'HourlyZekr');
    }
    await _appSettings.setHourlyTasbihSeeded(true);
  }

  Future<void> disable() async {
    for (final hour in _activeHours) {
      await _notifications.cancel(_baseId + hour);
    }
  }

  /// First preferred minute in [hour] that clears every reserved time. Compared
  /// in absolute minutes-of-day, so a prayer at 12:55 correctly blocks 13:00.
  int _minuteForHour(int hour, List<int> reserved) =>
      NotificationSlots.pickMinute(
        hour: hour,
        reserved: reserved,
        candidates: _minuteCandidates,
      );

  String _bodyForHour(int hour) {
    final list = _azkar;
    if (list == null || list.isEmpty) {
      return _phrases[hour % _phrases.length];
    }
    final row = list[hour % list.length];
    final lang = LocalizeAndTranslate.getLanguageCode();
    return (lang == 'en' ? row['en'] : row['ar']) ?? row['ar'] ?? '';
  }

  Future<void> _loadAzkar() async {
    if (_azkar != null) return;
    try {
      final root =
          jsonDecode(await rootBundle.loadString(_assetPath)) as Map;
      final rows = (root['hourly_azkar'] as List?) ?? const [];
      _azkar = [
        for (final r in rows)
          if (r is Map)
            {
              'ar': (r['text_ar'] ?? '').toString(),
              'en': (r['text_en'] ?? '').toString(),
            },
      ];
    } catch (e) {
      AppLogger.warning(
        'Failed to load $_assetPath — using fallback phrases ($e)',
        tag: 'HourlyZekr',
      );
      _azkar = const [];
    }
  }
}
