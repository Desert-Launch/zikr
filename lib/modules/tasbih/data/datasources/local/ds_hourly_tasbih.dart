import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/extension/string_extensions.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/notification_channels.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
import 'package:quran/core/services/notifications/notification_slots.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/core/services/notifications/reminder_sound_alarms.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_counter.dart';

/// Schedules the hourly zekr notifications (Decision 2). One per hour of the
/// user's reminder window (08:00–22:00 until they change it — see
/// `BoxAppSettings.reminderWindow`), silent + low importance — see
/// [AppNotificationChannels.hourly].
///
/// Phrases are loaded from `assets/data/notifictaions/hourly_notifications.json`
/// (falling back to a hard-coded list), rotated with `hour % len`.
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
/// the only one of the three Dart can actually see.
///
/// **Same-hour conflict avoidance:** other feeds (prayer, azkar/quran init)
/// also land on the hour boundary, so passing their [reservedTimes] shifts a
/// colliding hourly slot off `:00` to keep a 10-minute gap. Only the minute
/// changes — the id (`_baseId + hour`) stays stable so cancel/reschedule is
/// symmetric.
///
/// Notification IDs reserved: 5000..5023 (one per hour, `_baseId + hour`).
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

  /// Hours to schedule, from the user's reminder window (08:00–22:00 until
  /// they change it) — the same window the salawat reminder uses, and the only
  /// other feed it governs.
  List<int> get _activeHours => _appSettings.reminderWindow().hours;

  /// Preferred minutes, in order. `:00` first (the true "hourly" cadence);
  /// shift to `:10`/`:20`/`:50` etc. only when a reserved time collides. `:30`
  /// is last so we don't step on the salawat reminder (which fires at `:30`).
  static const _minuteCandidates = [0, 10, 20, 50, 40, 15, 45, 5, 25, 30];

  /// Fallback phrases — cycled with `hour % len` when the JSON can't be read.
  /// Same zekr, same order as the JSON rows.
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

  /// (Re)schedules every active hour. [reservedTimes] are times already claimed
  /// by other feeds today; any hour that would collide is shifted off `:00`.
  /// Omit it to reuse the set from the last coordinated run.
  Future<void> enable({List<DateTime>? reservedTimes}) async {
    final reserved = reservedTimes ?? _lastReserved;
    _lastReserved = reserved;
    await _loadAzkar();
    // Clear the previous window first: narrowing it (or wrapping it past
    // midnight) would otherwise leave the hours it no longer covers scheduled
    // and firing. `scheduleDaily` overwrites by id, so re-arming right after is
    // safe, and the ids are stable per hour.
    await disable();
    // Each placed slot joins the reserved set so consecutive hours can't be
    // shifted onto each other (e.g. 12:50 and 13:00).
    final taken = NotificationSlots.minutesOfDay(reserved);
    final hours = _activeHours;
    final settings = _appSettings.current();
    final withAudio = settings.hourlyZikrSound;
    // The per-zekr sounding channels are retired whatever this is set to —
    // the audio is app-played now — and ten dead entries in the phone's
    // notification settings would read as if they still did something.
    await _deleteZikrChannels();
    var audible = 0;
    for (final hour in hours) {
      final minute = _minuteForHour(hour, taken);
      taken.add(hour * 60 + minute);
      final row = _rowForHour(hour);
      final slug = withAudio ? await _clipFor(row) : null;
      if (slug != null) audible++;
      await _notifications.scheduleDaily(
        id: _baseId + hour,
        hour: hour,
        minute: minute,
        title: "zikr_allah".translated,
        body: _bodyOf(row, hour),
        channel: slug == null
            ? AppNotificationChannels.hourly
            : AppNotificationChannels.hourlyAppSound,
        // iOS has no channels: the sound rides on the notification itself, and
        // an unbundled name would make it fall back to the default tone — hence
        // the same `slug != null` gate as Android.
        iosSound: slug == null ? null : '$slug.caf',
        payload: const NotificationPayload(type: 'hourly'),
      );
      // Android's half of the audio (a no-op elsewhere). An hour with no clip
      // arms nothing; [disable] above already cleared its previous one.
      if (slug != null) {
        await _sound.scheduleDaily(
          id: _baseId + hour,
          hour: hour,
          minute: minute,
          rawRes: slug,
          volume: settings.hourlyZikrVolume,
          throughSilent: false,
        );
      }
    }
    AppLogger.info(
      'Hourly zekr scheduled (${hours.length} slots, $audible with audio, '
      '${reserved.length} reserved times)',
      tag: 'HourlyZekr',
    );
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
  /// For settings changes that carry no prayer-time context — the on/off switch
  /// or a reminder-window move. Passing an empty list to
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

  /// Cancels every hour this source may have scheduled.
  ///
  /// Sweeps the whole day rather than the current window, for the same reason
  /// [DSSalawatReminder.disable] does: hours dropped by a narrowed window would
  /// otherwise stay armed and keep firing outside it. Takes the app-played
  /// clips with it, by id, leaving the salawat reminder's alone.
  Future<void> disable() async {
    final ids = [for (var hour = 0; hour < 24; hour++) _baseId + hour];
    for (final id in ids) {
      await _notifications.cancel(id);
    }
    await _sound.cancelIds(ids);
  }

  /// First preferred minute in [hour] that clears every reserved time. Compared
  /// in absolute minutes-of-day, so a prayer at 12:55 correctly blocks 13:00.
  int _minuteForHour(int hour, List<int> reserved) =>
      NotificationSlots.pickMinute(hour: hour, reserved: reserved, candidates: _minuteCandidates);

  /// The zekr rotated onto [hour], or null when the JSON couldn't be read (the
  /// caller then falls back to [_phrases], which carry no audio).
  Map<String, String>? _rowForHour(int hour) {
    final list = _azkar;
    if (list == null || list.isEmpty) return null;
    return list[hour % list.length];
  }

  String _bodyOf(Map<String, String>? row, int hour) {
    if (row == null) return _phrases[hour % _phrases.length];
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
