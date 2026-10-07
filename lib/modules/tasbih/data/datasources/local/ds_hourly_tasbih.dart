import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/data/models/m_app_settings.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/extension/string_extensions.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/hourly_rotation.dart';
import 'package:quran/core/services/notifications/notification_budget.dart';
import 'package:quran/core/services/notifications/notification_channels.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
import 'package:quran/core/services/notifications/notification_slots.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/core/services/notifications/reminder_sound_alarms.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_counter.dart';

/// Schedules the hourly zekr notifications (Decision 2). One per hour of the
/// hourly range (08:00–22:00 until the user changes it — see
/// `BoxAppSettings.hourlyWindow`), silent + low importance — see
/// [AppNotificationChannels.hourly].
///
/// Phrases are loaded from `assets/data/notifictaions/hourly_notifications.json`
/// (falling back to a hard-coded list) and handed out in order from the start
/// of the range — see [HourlyRotation]:
///
///  * **The azkar fit in one day** (the range has at least as many hours):
///    daily repeats, ids `_baseId + hour`. They keep firing whether or not the
///    app is ever opened again.
///  * **The range is shorter**: each day continues where the previous one
///    stopped, so the day's azkar differ and no daily repeat can carry them.
///    Armed instead as dated one-shots for the next [_rollingDays] days, ids
///    `_rollingBaseId + dayOffset * 24 + hour`, and re-armed on every launch
///    and resume (`AdhanScheduler.reconcileCompanionNotifications`) — so they
///    run out if the app goes unopened for that long.
///
/// **Per-zekr audio:** each JSON row may name a `sound` slug, whose clip is
/// bundled three times over — `<sound_dir>/<slug>.mp3` for Flutter (the JSON's
/// `sound_dir`, `assets/audio/hourly-notification/`), `res/raw/<slug>.mp3` for
/// Android, and `<slug>.caf` in the iOS bundle (`tool/sync_zikr_sounds.py`
/// publishes the two native copies). When
/// `MAppSettings.hourlyZikrSound` is on, iOS carries the matching sound on the
/// notification itself, while Android posts on the silent
/// [AppNotificationChannels.hourlyAppSound] and plays the clip through
/// [ReminderSoundAlarms] at `MAppSettings.hourlyZikrVolume` — a channel sound
/// can only play at the system notification volume, so this is what gives the
/// zekr a volume of its own. That clip still stays quiet on silent/vibrate, in
/// Do Not Disturb and during a call, as the channel sound did. When the audio
/// is off — or the clip isn't bundled — the hour falls back to the silent
/// [AppNotificationChannels.hourly]. The Flutter asset is what's probed for
/// that decision: it ships in the same commit as the native copies, and it is
/// the only one of the three Dart can actually see. In the rolling mode the
/// clip is a one-shot too ([ReminderSoundAlarms.scheduleAt]), as it changes
/// with the day's zekr.
///
/// **Same-hour conflict avoidance:** other feeds (prayer, azkar/quran init)
/// also land on the hour boundary, so passing their [reservedTimes] shifts a
/// colliding hourly slot off `:00` to keep a 10-minute gap. Only the minute
/// changes — the ids stay stable per hour so cancel/reschedule is symmetric.
///
/// **iOS:** at most [NotificationBudget.hourlyZikr] requests in either mode —
/// past the OS's 64-request cap the extra adds are dropped silently and starve
/// other feeds. That caps the rolling mode's horizon (5 hours → 3 days) and,
/// for a range over 15 hours, leaves its last hours unarmed.
///
/// Notification IDs reserved: 5000..5023 (daily, `_baseId + hour`) and
/// 5200..5391 (rolling, `_rollingBaseId + dayOffset * 24 + hour`).
class DSHourlyTasbih {
  DSHourlyTasbih(
    this._notifications,
    this._counter,
    this._appSettings, [
    ReminderSoundAlarms? sound,
  ]) : _sound = sound ?? ReminderSoundAlarms();

  final NotificationsService _notifications;
  final BoxTasbihCounter _counter;
  final BoxAppSettings _appSettings;
  final ReminderSoundAlarms _sound;

  static const _assetPath = 'assets/data/notifictaions/hourly_notifications.json';

  static const _baseId = 5000;

  /// Base of the rolling mode's ids — `+ dayOffset * 24 + hour`, the offset
  /// counted in calendar days from today.
  static const _rollingBaseId = 5200;

  /// Window-days the rolling mode arms ahead (Android; iOS stops sooner, at
  /// [NotificationBudget.hourlyZikr]). Each slot is a notification plus a clip
  /// alarm, so 7 days of a range just short of the 12 azkar is ~150 alarms —
  /// comfortably inside Android's 500-per-app cap next to the adhan window.
  static const _rollingDays = 7;

  /// Calendar days the rolling ids span: one more than [_rollingDays], as the
  /// last window-day of a range running past midnight ends the day after.
  static const _rollingDateSpan = _rollingDays + 1;

  /// Every id either mode may have armed.
  static final List<int> _allIds = [
    for (var hour = 0; hour < 24; hour++) _baseId + hour,
    for (var i = 0; i < _rollingDateSpan * 24; i++) _rollingBaseId + i,
  ];

  /// Preferred minutes, in order. `:00` first (the true "hourly" cadence);
  /// shift to `:10`/`:20`/`:50` etc. only when a reserved time collides. `:30`
  /// is last so we don't step on the salawat reminder (which fires at `:30`).
  static const _minuteCandidates = [0, 10, 20, 50, 40, 15, 45, 5, 25, 30];

  /// Fallback phrases — rotated like the JSON rows when the JSON can't be
  /// read. Same zekr, same order.
  static const _phrases = [
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'اللَّهُ أَكْبَرُ',
    'لَا إِلَهَ إِلَّا اللَّهُ',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    'سُبْحَانَ اللَّهِ الْعَظِيمِ',
    'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    'حَسْبِيَ اللَّهُ وَنِعْمَ الْوَكِيلُ',
    'اللَّهُ اللَّهُ رَبِّي لَا أُشْرِكُ بِهِ شَيْئًا',
    'وَأُفَوِّضُ أَمْرِي إِلَى اللَّهِ إِنَّ اللَّهَ بَصِيرٌ بِالْعِبَادِ',
  ];

  /// Where the zekr clips live when the JSON names no `sound_dir`.
  static const _defaultSoundDir = 'assets/audio/hourly-notification';

  /// Directory holding the zekr clips — the JSON's `sound_dir`, read by
  /// [_loadAzkar].
  String _soundDir = _defaultSoundDir;

  /// Cached `{ar, en, sound}` phrase rows loaded from JSON (null until first
  /// load). `sound` is the clip slug, empty when the row declares none.
  List<Map<String, String>>? _azkar;

  /// Memoized `slug -> is the clip actually bundled` probes, so re-scheduling
  /// doesn't re-read every asset. Cleared only by a restart, which is also the
  /// only way a bundled asset can change.
  final Map<String, bool> _clipBundled = {};

  /// Times claimed by the other feeds on the last coordinated run. Cached so a
  /// UI-triggered toggle (which carries no prayer-time context) still places
  /// the slots around the known prayer / azkar / salawat times.
  List<DateTime> _lastReserved = const [];

  /// How many azkar the feed rotates through — the JSON's rows, or the
  /// fallback phrases when it couldn't be read. Loads the JSON on first use.
  Future<int> zikrCount() async {
    await _loadAzkar();
    return _zikrCount;
  }

  int get _zikrCount {
    final loaded = _azkar?.length ?? 0;
    return loaded > 0 ? loaded : _phrases.length;
  }

  /// (Re)schedules every hour of the range. [reservedTimes] are times already
  /// claimed by other feeds today; any hour that would collide is shifted off
  /// `:00`. Omit it to reuse the set from the last coordinated run.
  Future<void> enable({List<DateTime>? reservedTimes}) async {
    final reserved = reservedTimes ?? _lastReserved;
    _lastReserved = reserved;
    await _loadAzkar();
    // Clear the previous schedule first: narrowing the range (or wrapping it
    // past midnight, or switching between the daily and rolling modes) would
    // otherwise leave hours it no longer covers armed and firing.
    await disable();
    final hours = _appSettings.hourlyWindow().hours;
    // One minute per hour, picked against today's reserved times and reused
    // on every day the rolling mode arms — prayer times drift a minute or two
    // a day, well inside the 10-minute gap. Each placed slot joins the
    // reserved set so consecutive hours can't be shifted onto each other
    // (e.g. 12:50 and 13:00).
    final taken = NotificationSlots.minutesOfDay(reserved);
    final minutes = <int>[];
    for (final hour in hours) {
      final minute = _minuteForHour(hour, taken);
      taken.add(hour * 60 + minute);
      minutes.add(minute);
    }
    final settings = _appSettings.current();
    // The per-zekr sounding channels are retired whatever this is set to —
    // the audio is app-played now — and ten dead entries in the phone's
    // notification settings would read as if they still did something.
    await _deleteZikrChannels();
    final rotation = HourlyRotation(
      slotsPerDay: hours.length,
      zikrCount: _zikrCount,
    );
    final (armed, audible) = rotation.fitsInOneDay
        ? await _armDaily(hours, minutes, rotation, settings)
        : await _armRolling(hours, minutes, rotation, settings);
    AppLogger.info(
      'Hourly zekr scheduled (${rotation.fitsInOneDay ? 'daily' : 'rolling'}: '
      '${hours.length} hours, $_zikrCount azkar, $armed armed, $audible with '
      'audio, ${reserved.length} reserved times)',
      tag: 'HourlyZekr',
    );
  }

  /// Every zekr fits in the range: slot `i` repeats zekr `i` daily. Returns
  /// how many slots were armed and how many of them carry audio.
  Future<(int, int)> _armDaily(
    List<int> hours,
    List<int> minutes,
    HourlyRotation rotation,
    MAppSettings settings,
  ) async {
    final count = Platform.isIOS
        ? min(hours.length, NotificationBudget.hourlyZikr)
        : hours.length;
    if (count < hours.length) {
      AppLogger.warning(
        'Hourly range has ${hours.length} hours — only the first $count fit '
        'the iOS notification budget',
        tag: 'HourlyZekr',
      );
    }
    var audible = 0;
    for (var slot = 0; slot < count; slot++) {
      final withAudio = await _armSlot(
        id: _baseId + hours[slot],
        rowIndex: rotation.rowFor(day: 0, slot: slot),
        hour: hours[slot],
        minute: minutes[slot],
        settings: settings,
      );
      if (withAudio) audible++;
    }
    return (count, audible);
  }

  /// The range is shorter than the azkar list: arms each upcoming slot of the
  /// next [_rollingDays] window-days as a one-shot carrying that day's zekr.
  /// Returns how many slots were armed and how many of them carry audio.
  Future<(int, int)> _armRolling(
    List<int> hours,
    List<int> minutes,
    HourlyRotation rotation,
    MAppSettings settings,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayNumber = HourlyRotation.epochDay(today);
    final cap = Platform.isIOS ? NotificationBudget.hourlyZikr : null;
    var armed = 0;
    var audible = 0;
    // Starts with yesterday's window-day: a range running past midnight may
    // still have hours of it left today.
    for (var offset = -1; offset < _rollingDays; offset++) {
      final windowDay = DateTime(today.year, today.month, today.day + offset);
      final day =
          HourlyRotation.epochDay(windowDay) -
          settings.hourlyRotationAnchorDay;
      for (var slot = 0; slot < hours.length; slot++) {
        if (cap != null && armed >= cap) return (armed, audible);
        final at = HourlyRotation.fireTime(
          windowDay,
          hours,
          slot,
          minutes[slot],
        );
        if (!at.isAfter(now)) continue;
        final dateOffset = HourlyRotation.epochDay(at) - todayNumber;
        final withAudio = await _armSlot(
          id: _rollingBaseId + dateOffset * 24 + hours[slot],
          rowIndex: rotation.rowFor(day: day, slot: slot),
          hour: hours[slot],
          minute: minutes[slot],
          at: at,
          settings: settings,
        );
        armed++;
        if (withAudio) audible++;
      }
    }
    return (armed, audible);
  }

  /// Arms one slot with the zekr at [rowIndex] — a daily repeat at
  /// [hour]:[minute], or a one-shot at [at] when given. Returns whether it
  /// carries the zekr's audio.
  Future<bool> _armSlot({
    required int id,
    required int rowIndex,
    required int hour,
    required int minute,
    required MAppSettings settings,
    DateTime? at,
  }) async {
    final row = _rowAt(rowIndex);
    final slug = settings.hourlyZikrSound ? await _clipFor(row) : null;
    final title = 'zikr_allah'.translated;
    final body = _bodyOf(row, rowIndex);
    final channel = slug == null
        ? AppNotificationChannels.hourly
        : AppNotificationChannels.hourlyAppSound;
    // iOS has no channels: the sound rides on the notification itself, and an
    // unbundled name would make it fall back to the default tone — hence the
    // same `slug != null` gate as Android.
    final iosSound = slug == null ? null : '$slug.caf';
    const payload = NotificationPayload(type: 'hourly');
    if (at == null) {
      await _notifications.scheduleDaily(
        id: id,
        hour: hour,
        minute: minute,
        title: title,
        body: body,
        channel: channel,
        iosSound: iosSound,
        payload: payload,
      );
    } else {
      await _notifications.scheduleAt(
        id: id,
        when: at,
        title: title,
        body: body,
        channel: channel,
        iosSound: iosSound,
        payload: payload,
      );
    }
    // Android's half of the audio (a no-op elsewhere). A slot with no clip
    // arms nothing; [disable] already cleared its previous one.
    if (slug == null) return false;
    if (at == null) {
      await _sound.scheduleDaily(
        id: id,
        hour: hour,
        minute: minute,
        rawRes: slug,
        volume: settings.hourlyZikrVolume,
        throughSilent: false,
      );
    } else {
      await _sound.scheduleAt(
        id: id,
        when: at,
        rawRes: slug,
        volume: settings.hourlyZikrVolume,
        throughSilent: false,
      );
    }
    return true;
  }

  /// The clip slug for [row], or null when it declares none or the clip isn't
  /// bundled yet. Probing the Flutter asset is what keeps a half-supplied set
  /// working: those hours stay silent instead of firing a channel pointed at a
  /// missing `res/raw` resource.
  Future<String?> _clipFor(Map<String, String>? row) async {
    final slug = row?['sound'] ?? '';
    if (slug.isEmpty) return null;
    final bundled = _clipBundled[slug] ??= await _isBundled(slug);
    return bundled ? slug : null;
  }

  Future<bool> _isBundled(String slug) async {
    try {
      await rootBundle.load('$_soundDir/$slug.mp3');
      return true;
    } catch (_) {
      AppLogger.warning(
        'Zekr clip $slug.mp3 not bundled — that hour stays silent. '
        'See $_soundDir/ZIKR_SOUNDS.md',
        tag: 'HourlyZekr',
      );
      return false;
    }
  }

  /// Removes every retired per-zekr channel this source may have created on an
  /// earlier build. Best-effort: a channel that was never created is a no-op
  /// delete.
  Future<void> _deleteZikrChannels() async {
    for (final row in _azkar ?? const <Map<String, String>>[]) {
      final slug = row['sound'] ?? '';
      if (slug.isEmpty) continue;
      await _notifications.deleteChannel(AppNotificationChannels.hourlyZikrChannelId(slug));
    }
  }

  /// Recomputes the hourly schedule against a fresh [reservedTimes] set — call
  /// this once prayer + azkar times are known (from the adhan reschedule). No-op
  /// when the user has the hourly zekr turned off.
  Future<void> rescheduleWithReservedTimes(List<DateTime> reservedTimes) async {
    // Recorded even when the feature is off, so switching it on later from the
    // UI (which passes no reserved times) still lands on conflict-free slots.
    _lastReserved = reservedTimes;
    await seedDefaultIfNeeded();
    if (!_counter.current().hourlyEnabled) return;
    await enable(reservedTimes: reservedTimes);
  }

  /// Rebuilds from the persisted settings, reusing the reserved times from the
  /// last coordinated run.
  ///
  /// For settings changes that carry no prayer-time context — the on/off switch,
  /// the audio settings or a range move. Passing an empty list to
  /// [rescheduleWithReservedTimes] instead would work, but would also overwrite
  /// the cached reserved set with nothing, so the rebuilt slots would drop back
  /// onto times the prayer and azkar feeds have already claimed.
  Future<void> rescheduleFromSettings() async {
    if (!_counter.current().hourlyEnabled) {
      await disable();
      return;
    }
    await enable();
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

  /// Cancels everything this source may have scheduled, in either mode.
  ///
  /// Sweeps both id bands rather than the current range, for the same reason
  /// [DSSalawatReminder.disable] does: hours dropped by a narrowed range would
  /// otherwise stay armed and keep firing outside it. Takes the app-played
  /// clips with it, by id, leaving the salawat reminder's alone.
  ///
  /// Notifications are cancelled only where actually pending: the bands hold
  /// 216 ids, and on Android every plugin `cancel` reloads and rewrites its
  /// whole scheduled-notification cache — too slow to repeat on each launch.
  Future<void> disable() async {
    final pending = {
      for (final request in await _notifications.pending()) request.id,
    };
    for (final id in _allIds) {
      if (pending.contains(id)) await _notifications.cancel(id);
    }
    await _sound.cancelIds(_allIds);
  }

  /// First preferred minute in [hour] that clears every reserved time. Compared
  /// in absolute minutes-of-day, so a prayer at 12:55 correctly blocks 13:00.
  int _minuteForHour(int hour, List<int> reserved) =>
      NotificationSlots.pickMinute(hour: hour, reserved: reserved, candidates: _minuteCandidates);

  /// The zekr at [index] of the rotation, or null when the JSON couldn't be
  /// read (the caller then falls back to [_phrases], which carry no audio).
  Map<String, String>? _rowAt(int index) {
    final list = _azkar;
    if (list == null || list.isEmpty) return null;
    return list[index % list.length];
  }

  String _bodyOf(Map<String, String>? row, int index) {
    if (row == null) return _phrases[index % _phrases.length];
    final lang = LocalizeAndTranslate.getLanguageCode();
    return (lang == 'en' ? row['en'] : row['ar']) ?? row['ar'] ?? '';
  }

  Future<void> _loadAzkar() async {
    if (_azkar != null) return;
    try {
      final root = jsonDecode(await rootBundle.loadString(_assetPath)) as Map;
      final dir = (root['sound_dir'] ?? '').toString();
      if (dir.isNotEmpty) _soundDir = dir;
      final rows = (root['hourly_azkar'] as List?) ?? const [];
      _azkar = [
        for (final r in rows)
          if (r is Map)
            {
              'ar': (r['text_ar'] ?? '').toString(),
              'en': (r['text_en'] ?? '').toString(),
              'sound': (r['sound'] ?? '').toString(),
            },
      ];
    } catch (e) {
      AppLogger.warning('Failed to load $_assetPath — using fallback phrases ($e)', tag: 'HourlyZekr');
      _azkar = const [];
    }
  }
}
