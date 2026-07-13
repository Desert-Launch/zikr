import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/notification_box/ds_notification.dart';
import 'package:quran/core/services/notifications/notification_box/m_notification.dart';
import 'package:quran/core/services/notifications/notification_channels.dart';
import 'package:quran/core/services/notifications/notification_ids.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';

/// Schedules the "init" notification feed — the daily/weekly azkar and Quran
/// reminders defined in `assets/data/notifictaions/init_notifications.json`.
///
/// Content (title/body, localized) lives in the JSON; timing for the morning
/// and evening azkar is dynamic — it tracks live prayer times via
/// [updateAzkarNotifications] (morning → Fajr+1h, evening → Maghrib−15m). The
/// JSON `time` values are the seed/fallback used until prayer times are known.
///
/// Every scheduled entry is persisted via [DSNotification] so the schedule can
/// be reconciled and re-timed across restarts.
class InitNotificationsService {
  InitNotificationsService(this._notifications, this._store, this._appSettings);

  final NotificationsService _notifications;
  final DSNotification _store;
  final BoxAppSettings _appSettings;

  static const _assetPath =
      'assets/data/notifictaions/init_notifications.json';

  /// azkar ids whose fire time tracks prayer times (re-timed by
  /// [updateAzkarNotifications]); everything else keeps its JSON seed time.
  static const _autoScheduleIds = {'azkar_morning', 'azkar_evening'};

  String _defaultLocale = 'ar';

  /// Schedules the feed once per install. Guarded by the
  /// `initNotificationsScheduled` flag so it only seeds on first run; live
  /// re-timing afterwards goes through [updateAzkarNotifications].
  Future<void> scheduleInitialNotificationsIfNeeded() async {
    if (_appSettings.current().initNotificationsScheduled) return;
    await _scheduleAll();
    await _appSettings.setInitNotificationsScheduled(true);
  }

  /// Cancels + clears the stored init notifications and reschedules from JSON.
  /// Used when the user re-enables the feed from settings.
  Future<void> resetAndReschedule() async {
    for (final n in _store.byType('azkar')) {
      await _notifications.cancel(n.id);
      await _store.delete(n.id);
    }
    for (final n in _store.byType('quran')) {
      await _notifications.cancel(n.id);
      await _store.delete(n.id);
    }
    await _scheduleAll();
    await _appSettings.setInitNotificationsScheduled(true);
  }

  /// Re-times the auto-scheduled azkar to track live prayer times:
  /// morning → [fajrTime] + 1h, evening → [maghribTime] − 15m. No-op for a
  /// prayer whose time is null (keeps the current seed time). Recompute this on
  /// every prayer-time refresh (location / date change).
  Future<void> updateAzkarNotifications({
    DateTime? fajrTime,
    DateTime? maghribTime,
  }) async {
    if (fajrTime != null) {
      await _retime(
        NotificationIds.azkarMorning,
        fajrTime.add(const Duration(hours: 1)),
      );
    }
    if (maghribTime != null) {
      await _retime(
        NotificationIds.azkarEvening,
        maghribTime.subtract(const Duration(minutes: 15)),
      );
    }
  }

  /// Today's fire times for every stored init notification that fires today —
  /// used by the hourly-zekr scheduler to avoid same-hour collisions.
  List<DateTime> occupiedTimesToday() {
    final now = DateTime.now();
    final out = <DateTime>[];
    for (final n in _store.getAll()) {
      if (!n.isEnabled) continue;
      if (n.isWeekly && n.weekday != now.weekday) continue;
      out.add(
        DateTime(
          now.year,
          now.month,
          now.day,
          n.scheduledAt.hour,
          n.scheduledAt.minute,
        ),
      );
    }
    return out;
  }

  Future<void> _retime(int id, DateTime when) async {
    final record = _store.get(id);
    if (record == null || !record.autoSchedule || !record.isEnabled) return;
    await _notifications.scheduleDaily(
      id: id,
      hour: when.hour,
      minute: when.minute,
      title: record.title,
      body: record.body,
      channel: _channelFor(record.channelId),
      payload: NotificationPayload(
        type: record.payloadType,
        data: _decodeData(record.payloadJson),
      ),
    );
    record.scheduledAt = DateTime(
      when.year,
      when.month,
      when.day,
      when.hour,
      when.minute,
    );
    await _store.put(record);
    AppLogger.info(
      'Re-timed init notification $id to ${when.hour}:${when.minute}',
      tag: 'InitNotifications',
    );
  }

  Future<void> _scheduleAll() async {
    final Map<String, dynamic> root;
    try {
      root = jsonDecode(await rootBundle.loadString(_assetPath))
          as Map<String, dynamic>;
    } catch (e, st) {
      AppLogger.error(
        'Failed to load $_assetPath',
        tag: 'InitNotifications',
        error: e,
        stackTrace: st,
      );
      return;
    }

    _defaultLocale = root['default_locale'] as String? ?? 'ar';
    final entries = (root['notifications'] as List?) ?? const [];
    var scheduled = 0;
    for (final raw in entries) {
      if (raw is! Map<String, dynamic>) continue;
      if (await _scheduleEntry(raw)) scheduled++;
    }
    AppLogger.info(
      'Init notifications scheduled: $scheduled/${entries.length}',
      tag: 'InitNotifications',
    );
  }

  /// Returns true if the entry was scheduled.
  Future<bool> _scheduleEntry(Map<String, dynamic> entry) async {
    if (entry['enabled'] == false) return false;

    final stringId = entry['id'] as String? ?? '';
    final id = NotificationIds.forStringId(stringId);
    if (id == null) {
      AppLogger.warning(
        'Unknown init notification id "$stringId" — skipped',
        tag: 'InitNotifications',
      );
      return false;
    }

    final content = (entry['content'] as Map?)?.cast<String, dynamic>() ?? {};
    final title = _localized(content['title']);
    final body = _localized(content['body']);
    final channel = _channelFor(content['channel_id'] as String?);
    final payload = _resolvePayload(entry);
    final schedule = (entry['schedule'] as Map?)?.cast<String, dynamic>() ?? {};
    final time = _parseTime(schedule['time'] as String?);
    if (time == null) return false;

    final autoSchedule = _autoScheduleIds.contains(stringId);
    final now = DateTime.now();

    switch (schedule['type']) {
      case 'daily':
        await _notifications.scheduleDaily(
          id: id,
          hour: time.$1,
          minute: time.$2,
          title: title,
          body: body,
          channel: channel,
          payload: payload,
        );
        await _persist(
          id: id,
          title: title,
          body: body,
          channel: channel,
          payload: payload,
          scheduledAt: DateTime(now.year, now.month, now.day, time.$1, time.$2),
          repeatDaily: true,
          weekday: 0,
          autoSchedule: autoSchedule,
        );
        return true;
      case 'weekly':
        final weekday = _parseWeekday(schedule['day'] as String?);
        if (weekday == null) return false;
        await _notifications.scheduleWeekly(
          id: id,
          weekday: weekday,
          hour: time.$1,
          minute: time.$2,
          title: title,
          body: body,
          channel: channel,
          payload: payload,
        );
        await _persist(
          id: id,
          title: title,
          body: body,
          channel: channel,
          payload: payload,
          scheduledAt: DateTime(now.year, now.month, now.day, time.$1, time.$2),
          repeatDaily: false,
          weekday: weekday,
          autoSchedule: autoSchedule,
        );
        return true;
      default:
        return false;
    }
  }

  Future<void> _persist({
    required int id,
    required String title,
    required String body,
    required AndroidNotificationChannel channel,
    required NotificationPayload payload,
    required DateTime scheduledAt,
    required bool repeatDaily,
    required int weekday,
    required bool autoSchedule,
  }) async {
    await _store.put(
      MLocalNotification(
        id: id,
        title: title,
        body: body,
        scheduledAt: scheduledAt,
        channelId: channel.id,
        repeatDaily: repeatDaily,
        weekday: weekday,
        payloadType: payload.type,
        payloadJson: jsonEncode(payload.data),
        autoSchedule: autoSchedule,
      ),
    );
  }

  /// Builds the tap payload. Azkar entries route to their category (by slug);
  /// Quran entries route to the reader at surah:1.
  NotificationPayload _resolvePayload(Map<String, dynamic> entry) {
    final type = entry['type'] as String? ?? 'unknown';
    final params =
        (entry['payload'] as Map?)?['params'] as Map? ?? const {};
    switch (type) {
      case 'azkar':
        return NotificationPayload(
          type: 'azkar',
          data: {'category': _azkarSlug(params['category']?.toString())},
        );
      case 'quran':
        final surah = (params['surahNumber'] as num?)?.toInt() ??
            ((entry['meta'] as Map?)?['surah_number'] as num?)?.toInt();
        return NotificationPayload(
          type: 'quran',
          data: {if (surah != null) 'surah': surah, 'ayah': 1},
        );
      default:
        return NotificationPayload(type: type);
    }
  }

  /// Normalizes the JSON category label to the app's azkar category slug
  /// (filename without `.json`). The feed says "sleep" but the bundled category
  /// is `sleeping`.
  String _azkarSlug(String? category) => switch (category) {
    'sleep' => 'sleeping',
    final c? when c.isNotEmpty => c,
    _ => 'morning',
  };

  AndroidNotificationChannel _channelFor(String? channelId) => switch (channelId) {
    'prayer_channel' => AppNotificationChannels.prayer,
    'al_muslim_local_notifications' => AppNotificationChannels.quranReminders,
    _ => AppNotificationChannels.azkar,
  };

  /// Resolves a `{ar, en}` localized value against the active language, falling
  /// back to [_defaultLocale] then any available value.
  String _localized(Object? value) {
    if (value is! Map) return value?.toString() ?? '';
    final map = value.cast<String, dynamic>();
    final lang = LocalizeAndTranslate.getLanguageCode();
    return (map[lang] ?? map[_defaultLocale] ?? map.values.firstOrNull ?? '')
        .toString();
  }

  /// "08:00" → (8, 0). Null on malformed input.
  (int, int)? _parseTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (h, m);
  }

  int? _parseWeekday(String? day) => switch (day?.toLowerCase()) {
    'monday' => DateTime.monday,
    'tuesday' => DateTime.tuesday,
    'wednesday' => DateTime.wednesday,
    'thursday' => DateTime.thursday,
    'friday' => DateTime.friday,
    'saturday' => DateTime.saturday,
    'sunday' => DateTime.sunday,
    _ => null,
  };

  Map<String, dynamic> _decodeData(String json) {
    if (json.isEmpty) return const {};
    try {
      return Map<String, dynamic>.from(jsonDecode(json) as Map);
    } catch (_) {
      return const {};
    }
  }
}
