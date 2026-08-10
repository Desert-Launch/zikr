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
import 'package:quran/core/services/notifications/notification_slots.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';

/// Schedules the "init" notification feed — the daily/weekly azkar and Quran
/// reminders defined in `assets/data/notifictaions/init_notifications.json`.
///
/// Content (title/body, localized) lives in the JSON; timing for the morning
/// and evening azkar is dynamic — it tracks live prayer times (morning →
/// Fajr+1h, evening → Maghrib−15m). The JSON `time` values are the
/// seed/fallback used until prayer times are known.
///
/// Every scheduled entry is persisted via [DSNotification] so the schedule can
/// be reconciled and re-timed across restarts. [reconcile] is the single
/// placement pass — it re-registers the feed, re-times the prayer-tracked
/// entries, and spaces everything off the reserved times it's handed.
class InitNotificationsService {
  InitNotificationsService(this._notifications, this._store, this._appSettings);

  final NotificationsService _notifications;
  final DSNotification _store;
  final BoxAppSettings _appSettings;

  static const _assetPath =
      'assets/data/notifictaions/init_notifications.json';

  /// azkar ids whose fire time tracks live prayer times (see [_targetMinute]);
  /// everything else keeps its JSON seed time.
  static const _autoScheduleIds = {'azkar_morning', 'azkar_evening'};

  String _defaultLocale = 'ar';

  /// Re-registers every entry in the feed and returns the times it placed
  /// (today's clock times) so the caller can pass them on as reserved to the
  /// next feed. Safe — and intended — to run on every launch: the ids are
  /// stable, so each `zonedSchedule` overwrites its own pending alarm in place
  /// rather than stacking a duplicate.
  ///
  /// This is what makes the feed self-healing. Seeding once per install left an
  /// install whose alarms the OS dropped — force-stop, an app-data restore, a
  /// seed that ran before notifications were permitted — with the
  /// `initNotificationsScheduled` flag set and nothing actually queued.
  ///
  /// The morning and evening azkar track live prayer times when [fajrTime] /
  /// [maghribTime] are given (morning → Fajr+1h, evening → Maghrib−15m), and
  /// fall back to their stored time otherwise. Every entry is then nudged clear
  /// of [reservedTimes] (the prayer times) and of the entries already placed in
  /// this pass. A stored entry the user turned off stays off.
  Future<List<DateTime>> reconcile({
    List<DateTime> reservedTimes = const [],
    DateTime? fajrTime,
    DateTime? maghribTime,
  }) async {
    final placed = await _scheduleAll(
      preferStoredTimes: true,
      reservedTimes: reservedTimes,
      fajrTime: fajrTime,
      maghribTime: maghribTime,
    );
    await _appSettings.setInitNotificationsScheduled(true);
    return placed;
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

  /// Schedules every entry in the feed, returning the times placed today.
  Future<List<DateTime>> _scheduleAll({
    bool preferStoredTimes = false,
    List<DateTime> reservedTimes = const [],
    DateTime? fajrTime,
    DateTime? maghribTime,
  }) async {
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
      return const [];
    }

    _defaultLocale = root['default_locale'] as String? ?? 'ar';
    final entries = (root['notifications'] as List?) ?? const [];
    // Grows as entries are placed, so the feed also spaces itself internally.
    final taken = NotificationSlots.minutesOfDay(reservedTimes);
    final placed = <DateTime>[];
    for (final raw in entries) {
      if (raw is! Map<String, dynamic>) continue;
      final at = await _scheduleEntry(
        raw,
        preferStoredTimes: preferStoredTimes,
        taken: taken,
        fajrTime: fajrTime,
        maghribTime: maghribTime,
      );
      if (at == null) continue;
      taken.add(at.hour * 60 + at.minute);
      placed.add(at);
    }
    AppLogger.info(
      'Init notifications scheduled: ${placed.length}/${entries.length} '
      '(${reservedTimes.length} reserved times)',
      tag: 'InitNotifications',
    );
    return placed;
  }

  /// Schedules one entry and returns the time it was placed at (today's clock
  /// time), or null when it was skipped.
  ///
  /// [taken] is the running set of minutes-of-day already claimed; the entry is
  /// nudged off any of them. With [preferStoredTimes] a prayer-tracked entry
  /// falls back to its persisted time when [fajrTime] / [maghribTime] aren't
  /// available yet.
  Future<DateTime?> _scheduleEntry(
    Map<String, dynamic> entry, {
    required List<int> taken,
    bool preferStoredTimes = false,
    DateTime? fajrTime,
    DateTime? maghribTime,
  }) async {
    if (entry['enabled'] == false) return null;

    final stringId = entry['id'] as String? ?? '';
    final id = NotificationIds.forStringId(stringId);
    if (id == null) {
      AppLogger.warning(
        'Unknown init notification id "$stringId" — skipped',
        tag: 'InitNotifications',
      );
      return null;
    }

    final stored = preferStoredTimes ? _store.get(id) : null;
    // The user switched this one off — leave it cancelled.
    if (stored != null && !stored.isEnabled) {
      await _notifications.cancel(id);
      return null;
    }

    final content = (entry['content'] as Map?)?.cast<String, dynamic>() ?? {};
    final title = _localized(content['title']);
    final body = _localized(content['body']);
    final channel = _channelFor(content['channel_id'] as String?);
    final payload = _resolvePayload(entry);
    final schedule = (entry['schedule'] as Map?)?.cast<String, dynamic>() ?? {};
    final seed = _parseTime(schedule['time'] as String?);
    if (seed == null) return null;

    final autoSchedule = _autoScheduleIds.contains(stringId);
    final target = _targetMinute(
      stringId: stringId,
      autoSchedule: autoSchedule,
      seed: seed,
      stored: stored,
      fajrTime: fajrTime,
      maghribTime: maghribTime,
    );
    final minuteOfDay = NotificationSlots.nudge(
      minuteOfDay: target,
      reserved: taken,
    );
    final hour = minuteOfDay ~/ 60;
    final minute = minuteOfDay % 60;

    final now = DateTime.now();
    final at = DateTime(now.year, now.month, now.day, hour, minute);

    switch (schedule['type']) {
      case 'daily':
        await _notifications.scheduleDaily(
          id: id,
          hour: hour,
          minute: minute,
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
          scheduledAt: at,
          repeatDaily: true,
          weekday: 0,
          autoSchedule: autoSchedule,
        );
        return at;
      case 'weekly':
        final weekday = _parseWeekday(schedule['day'] as String?);
        if (weekday == null) return null;
        await _notifications.scheduleWeekly(
          id: id,
          weekday: weekday,
          hour: hour,
          minute: minute,
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
          scheduledAt: at,
          repeatDaily: false,
          weekday: weekday,
          autoSchedule: autoSchedule,
        );
        // Only claims a slot on the day it actually fires.
        return weekday == now.weekday ? at : null;
      default:
        return null;
    }
  }

  /// The minute-of-day an entry *wants* to fire at, before collision nudging.
  ///
  /// Prayer-tracked entries follow live prayer times when available and fall
  /// back to their stored time. Fixed entries always resolve to the JSON seed —
  /// never to the stored value, or each reconcile would nudge yesterday's
  /// already-nudged time and the reminder would drift a little further every
  /// day.
  int _targetMinute({
    required String stringId,
    required bool autoSchedule,
    required (int, int) seed,
    required MLocalNotification? stored,
    required DateTime? fajrTime,
    required DateTime? maghribTime,
  }) {
    if (!autoSchedule) return seed.$1 * 60 + seed.$2;

    final anchored = switch (stringId) {
      'azkar_morning' => fajrTime?.add(const Duration(hours: 1)),
      'azkar_evening' => maghribTime?.subtract(const Duration(minutes: 15)),
      _ => null,
    };
    if (anchored != null) return anchored.hour * 60 + anchored.minute;
    if (stored != null) {
      return stored.scheduledAt.hour * 60 + stored.scheduledAt.minute;
    }
    return seed.$1 * 60 + seed.$2;
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
}
