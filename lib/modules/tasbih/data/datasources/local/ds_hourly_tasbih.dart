import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/notification_channels.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
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
  DSHourlyTasbih(this._notifications, this._counter);

  final NotificationsService _notifications;
  final BoxTasbihCounter _counter;

  static const _assetPath =
      'assets/data/notifictaions/hourly_notifications.json';

  /// Minimum gap (minutes) enforced between an hourly zekr and any reserved
  /// notification in the same hour.
  static const _gap = 10;

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

  /// (Re)schedules every active hour. [reservedTimes] are times already claimed
  /// by other feeds today; any hour that would collide is shifted off `:00`.
  Future<void> enable({List<DateTime> reservedTimes = const []}) async {
    await _loadAzkar();
    for (final hour in _activeHours) {
      final minute = _minuteForHour(hour, reservedTimes);
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
      '${reservedTimes.length} reserved times)',
      tag: 'HourlyZekr',
    );
  }

  /// Recomputes the hourly schedule against a fresh [reservedTimes] set — call
  /// this once prayer + azkar times are known (from the adhan reschedule). No-op
  /// when the user has the hourly zekr turned off.
  Future<void> rescheduleWithReservedTimes(
    List<DateTime> reservedTimes,
  ) async {
    if (!_counter.current().hourlyEnabled) return;
    await enable(reservedTimes: reservedTimes);
  }

  Future<void> disable() async {
    for (final hour in _activeHours) {
      await _notifications.cancel(_baseId + hour);
    }
  }

  /// First preferred minute that keeps a [_gap]-minute distance from every
  /// reserved time in [hour]. Falls back to `:10` (off the `:00` boundary) if
  /// nothing clears — better than stacking on `:00`.
  int _minuteForHour(int hour, List<DateTime> reservedTimes) {
    final sameHour = reservedTimes
        .where((t) => t.hour == hour)
        .map((t) => t.minute)
        .toList(growable: false);
    if (sameHour.isEmpty) return 0;
    for (final minute in _minuteCandidates) {
      final clears = sameHour.every((m) => (m - minute).abs() >= _gap);
      if (clears) return minute;
    }
    return 10;
  }

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
