import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/notifications/notification_box/ds_notification.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/modules/adhan/data/datasources/local/ds_local_adhan.dart';
import 'package:quran/modules/adhan/data/models/m_adhan.dart';
import 'package:quran/modules/adhan/data/models/m_adhan_settings.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_download.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_preference.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_settings.dart';
import 'package:quran/modules/adhan/domain/usecases/uc_download_adhan_voice.dart';
import 'package:quran/modules/adhan/domain/usecases/uc_fetch_adhan_catalog.dart';
import 'package:quran/modules/adhan/presentation/cubits/s_adhan_settings.dart';
import 'package:quran/modules/adhan/services/adhan_scheduler.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_settings.dart';

/// Backs the adhan settings screen. Per-prayer toggles live in
/// `MPrayerSettings.notifyForPrayer`, voice in `MAdhanPreference`, and the
/// notification-behaviour fields in `MAdhanSettings`. Every change persists
/// and triggers a debounced [AdhanScheduler.reschedule].
class CBAdhanSettings extends Cubit<SAdhanSettings> {
  CBAdhanSettings({
    required BoxAdhanSettings adhanSettings,
    required BoxPrayerSettings prayerSettings,
    required BoxAdhanPreference adhanPrefs,
    required DSLocalAdhan local,
    required NotificationsService notifications,
    required AdhanScheduler scheduler,
    required DSNotification notificationStore,
    required UCFetchAdhanCatalog fetchCatalog,
    required UCDownloadAdhanVoice downloadVoice,
    required BoxAdhanDownload downloads,
  }) : _adhanSettings = adhanSettings,
       _prayerSettings = prayerSettings,
       _adhanPrefs = adhanPrefs,
       _local = local,
       _notifications = notifications,
       _scheduler = scheduler,
       _notificationStore = notificationStore,
       _fetchCatalog = fetchCatalog,
       _downloadVoice = downloadVoice,
       _downloads = downloads,
       super(const SAdhanSettings()) {
    load();
  }

  final BoxAdhanSettings _adhanSettings;
  final BoxPrayerSettings _prayerSettings;
  final BoxAdhanPreference _adhanPrefs;
  final DSLocalAdhan _local;
  final NotificationsService _notifications;
  final AdhanScheduler _scheduler;
  final DSNotification _notificationStore;
  final UCFetchAdhanCatalog _fetchCatalog;
  final UCDownloadAdhanVoice _downloadVoice;
  final BoxAdhanDownload _downloads;

  Timer? _debounce;

  Future<void> load() async {
    final s = _adhanSettings.current();
    final p = _prayerSettings.current();
    final hasPerm = await _notifications.hasPermission();
    final voiceName = await _selectedVoiceName();
    final voices = await _prayerVoices(p.adhanIdPerPrayer ?? const {});
    final pendingId = await _pendingDefaultDownloadId();
    final showBattery = await _shouldShowBatteryNote();
    emit(
      SAdhanSettings(
        loading: false,
        enabled: s.enabled,
        notifyForPrayer: List<bool>.of(p.notifyForPrayer),
        playbackMode: s.playbackMode,
        androidBackgroundFullAdhan: s.androidBackgroundFullAdhan,
        vibrate: s.vibrate,
        preNotifyMinutes: s.preNotifyMinutes,
        selectedVoiceNameAr: voiceName,
        voiceIdPerPrayer: Map<String, String>.of(
          p.adhanIdPerPrayer ?? const {},
        ),
        voiceNamePerPrayer: voices,
        hasPermission: hasPerm,
        needsDefaultDownload: pendingId != null,
        pendingDownloadVoiceId: pendingId,
        showBatteryNote: showBattery,
      ),
    );
  }

  /// Android-only: true when the app isn't exempt from battery optimization,
  /// so aggressive OEM power managers may delay or kill exact alarms. Used to
  /// surface a guidance note. Never throws.
  Future<bool> _shouldShowBatteryNote() async {
    if (!Platform.isAndroid) return false;
    try {
      return !await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the user to exempt the app from battery optimization (Android),
  /// then hides the note if granted.
  Future<void> requestBatteryExemption() async {
    if (!Platform.isAndroid) return;
    try {
      await Permission.ignoreBatteryOptimizations.request();
      final granted = await Permission.ignoreBatteryOptimizations.isGranted;
      emit(state.copyWith(showBatteryNote: !granted));
    } catch (_) {
      // Some OEMs reject the direct request; leave the note so the user can
      // still reach battery settings on a later attempt.
    }
  }

  /// The selected default voice id when it's a downloadable (remote) voice
  /// whose full file isn't on disk yet — e.g. the first-launch download failed
  /// offline. Null when nothing needs downloading (bundled voice, already
  /// downloaded, or no default chosen). Catalog fetch is best-effort and
  /// returns the bundled list offline, so this never throws.
  Future<String?> _pendingDefaultDownloadId() async {
    final defaultId = _adhanPrefs.current().defaultAdhanId;
    if (defaultId == null) return null;
    if (_downloads.isDownloaded(defaultId)) return null;
    final catalog = await _fetchCatalog();
    final voices = catalog.getOrElse(() => const <MAdhan>[]);
    for (final v in voices) {
      if (v.id == defaultId) {
        return v.isDownloadable ? defaultId : null;
      }
    }
    return null;
  }

  /// Re-attempts the default voice download from the settings prompt. Clears
  /// the prompt on success; leaves it (with an error) on failure.
  Future<void> retryDefaultDownload() async {
    final voiceId = state.pendingDownloadVoiceId;
    if (voiceId == null || state.retryingDownload) return;
    emit(state.copyWith(retryingDownload: true, clearError: true));
    final result = await _downloadVoice(voiceId);
    result.fold(
      (failure) => emit(
        state.copyWith(retryingDownload: false, error: failure.message),
      ),
      (_) => emit(
        state.copyWith(
          retryingDownload: false,
          needsDefaultDownload: false,
        ),
      ),
    );
  }

  Future<Map<String, String>> _prayerVoices(Map<String, String> ids) async {
    final fallback = await _selectedVoiceName();
    final names = <String, String>{};
    for (final key in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      final id = ids[key];
      final voice = id == null ? null : await _local.byId(id);
      names[key] = voice?.nameAr ?? fallback;
    }
    return names;
  }

  Future<String> _selectedVoiceName() async {
    final id = _adhanPrefs.current().defaultAdhanId;
    if (id == null) return '';
    final voice = await _local.byId(id);
    return voice?.nameAr ?? '';
  }

  Future<void> setEnabled(bool value) async {
    final s = _adhanSettings.current()..enabled = value;
    await _adhanSettings.save(s);
    emit(state.copyWith(enabled: value));
    if (value) {
      _scheduleSoon();
    } else {
      await _scheduler.cancelAll();
    }
  }

  Future<void> togglePrayer(int index, bool value) async {
    if (index < 0 || index > 4) return;
    if (value && !state.enabled) {
      final settings = _adhanSettings.current()..enabled = true;
      await _adhanSettings.save(settings);
      emit(state.copyWith(enabled: true));
    }
    final p = _prayerSettings.current();
    final updated = List<bool>.of(p.notifyForPrayer);
    if (index >= updated.length) return;
    updated[index] = value;
    p.notifyForPrayer = updated;
    await _prayerSettings.save(p);
    emit(state.copyWith(notifyForPrayer: updated));
    _scheduleSoon();
  }

  Future<void> setPrayerVoice(String prayerKey, String adhanId) async {
    const valid = {'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'};
    if (!valid.contains(prayerKey)) return;

    final prayer = _prayerSettings.current();
    final ids = Map<String, String>.of(prayer.adhanIdPerPrayer ?? const {});
    ids[prayerKey] = adhanId;
    prayer.adhanIdPerPrayer = ids;
    await _prayerSettings.save(prayer);

    final voice = await _local.byId(adhanId);
    final names = Map<String, String>.of(state.voiceNamePerPrayer);
    names[prayerKey] = voice?.nameAr ?? state.selectedVoiceNameAr;
    emit(state.copyWith(voiceIdPerPrayer: ids, voiceNamePerPrayer: names));
    _scheduleSoon();
  }

  Future<void> setPlaybackMode(String mode) async {
    final s = _adhanSettings.current()..playbackMode = mode;
    await _adhanSettings.save(s);
    emit(state.copyWith(playbackMode: mode));
  }

  /// Android-only Tier-2 toggle. Turning it on also flips [playbackMode] to
  /// `full` so the scheduler routes notifications to the per-voice `_full`
  /// channel (whose sound is the full adhan); off restores the short clip.
  /// Either way the window is rescheduled so the channel switch takes effect.
  Future<void> setAndroidBackground(bool value) async {
    final mode = value
        ? MAdhanSettings.playbackFull
        : MAdhanSettings.playbackClip;
    final s = _adhanSettings.current()
      ..androidBackgroundFullAdhan = value
      ..playbackMode = mode;
    await _adhanSettings.save(s);
    emit(state.copyWith(androidBackgroundFullAdhan: value, playbackMode: mode));
    _scheduleSoon();
  }

  Future<void> setVibrate(bool value) async {
    final s = _adhanSettings.current()..vibrate = value;
    await _adhanSettings.save(s);
    emit(state.copyWith(vibrate: value));
    _scheduleSoon();
  }

  Future<void> setPreNotifyMinutes(int minutes) async {
    final s = _adhanSettings.current()..preNotifyMinutes = minutes;
    await _adhanSettings.save(s);
    emit(state.copyWith(preNotifyMinutes: minutes));
    _scheduleSoon();
  }

  Future<void> requestPermission() async {
    final granted = await _notifications.requestPermission();
    emit(state.copyWith(hasPermission: granted));
    if (granted) _scheduleSoon();
  }

  /// Fires a one-shot test adhan ~1 minute from now to verify the end-to-end
  /// notification path independent of location / prayer-time fetching. Prompts
  /// for permission first if it's missing. Returns the scheduled fire time, or
  /// null if permission was denied (so the UI can warn instead of promising a
  /// notification that will never arrive).
  Future<DateTime?> scheduleTestAdhan() async {
    // Verify the live OS permission rather than trusting the cubit's cached
    // flag (which defaults to true and can go stale if the user revoked it in
    // system settings). Otherwise scheduleTest() skips with a warning and the
    // user never sees the permission prompt.
    var granted = await _notifications.hasPermission();
    if (!granted) {
      granted = await _notifications.requestPermission();
    }
    emit(state.copyWith(hasPermission: granted));
    if (!granted) return null;
    return _scheduler.scheduleTest();
  }

  /// Debug/testing helper: pretty-prints every notification currently scheduled
  /// with the OS (the real schedule store — there is no Hive box for pending
  /// notifications) as a single boxed, band-grouped table in the console, so
  /// pre-adhan alerts are easy to eyeball. Returns the total count for the UI.
  ///
  /// Emitted in one log call (not line-by-line) so Talker renders it as a
  /// single block instead of stamping every row with its own header.
  Future<int> debugDumpPending() async {
    final pending = await _notifications.pending();

    // Fire times come from two sources: the scheduler's in-session registry
    // (adhan/pre-adhan/test) and the persisted notification store (azkar/quran
    // init-feed entries, which the scheduler never places). Merge both, the
    // scheduler's live value winning when an id appears in both.
    final times = <int, DateTime>{};
    for (final r in pending) {
      final stored = _notificationStore.get(r.id);
      if (stored != null) times[r.id] = stored.scheduledAt;
    }
    times.addAll(_scheduler.scheduledTimes);

    // Group by feature band, then sort each group by fire time (falling back to
    // id) so the console reads chronologically.
    final groups = <String, List<PendingNotificationRequest>>{};
    for (final r in pending) {
      groups.putIfAbsent(_bandLabel(r.id), () => []).add(r);
    }
    for (final list in groups.values) {
      list.sort((a, b) {
        final ta = times[a.id];
        final tb = times[b.id];
        if (ta != null && tb != null) return ta.compareTo(tb);
        if (ta != null) return -1;
        if (tb != null) return 1;
        return a.id.compareTo(b.id);
      });
    }

    const order = ['adhan', 'pre-adhan', 'test', 'other'];
    final b = StringBuffer();
    b.writeln('\n┌────────────────────────────────────────────────────────────┐');
    b.writeln('│  SCHEDULED NOTIFICATIONS · ${pending.length} total');
    b.writeln('├────────────────────────────────────────────────────────────┤');
    if (pending.isEmpty) {
      b.writeln('│  (nothing scheduled)');
    }
    for (final band in order) {
      final list = groups[band];
      if (list == null || list.isEmpty) continue;
      b.writeln('│');
      b.writeln('│  ▸ ${band.toUpperCase()} (${list.length})');
      for (final r in list) {
        final tag = _payloadPrayer(r.payload);
        final when = times[r.id];
        b.writeln(
          '│    ${_fmtWhen(when)}  '
          'id ${r.id.toString().padRight(7)} '
          '${(r.title ?? '-')}${tag.isEmpty ? '' : '  · $tag'}',
        );
      }
    }
    b.writeln('└────────────────────────────────────────────────────────────┘');
    AppLogger.info(b.toString(), tag: 'AdhanDebug');
    return pending.length;
  }

  static const _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', //
  ];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Formats a fire time as a fixed-width `Tue 15 Jul  09:04` column. Shows a
  /// dash placeholder when the time is unknown (e.g. an entry scheduled in a
  /// previous session before the registry was populated).
  String _fmtWhen(DateTime? d) {
    if (d == null) return '     —  · · ·   ';
    final wd = _weekdays[d.weekday - 1];
    final mo = _months[d.month - 1];
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$wd $day $mo  $hh:$mm';
  }

  /// Human-readable band for a pending notification id, mirroring the id bands
  /// [AdhanScheduler] allocates.
  String _bandLabel(int id) {
    if (id >= 200000 && id < 300000) return 'adhan';
    if (id >= 300000 && id < 400000) return 'pre-adhan';
    if (id == 999999) return 'test';
    return 'other';
  }

  /// Pulls the `prayer` field out of an adhan/prayer notification payload for a
  /// compact label, e.g. `dhuhr`. Empty when absent or unparseable.
  String _payloadPrayer(String? raw) {
    if (raw == null) return '';
    final match = RegExp(r'"prayer"\s*:\s*"(\w+)"').firstMatch(raw);
    return match?.group(1) ?? '';
  }

  /// Re-reads the selected voice (called when returning from the picker).
  Future<void> refreshVoice() async {
    final selected = await _selectedVoiceName();
    final prayer = _prayerSettings.current();
    emit(
      state.copyWith(
        selectedVoiceNameAr: selected,
        voiceIdPerPrayer: Map<String, String>.of(
          prayer.adhanIdPerPrayer ?? const {},
        ),
        voiceNamePerPrayer: await _prayerVoices(
          prayer.adhanIdPerPrayer ?? const {},
        ),
      ),
    );
    _scheduleSoon();
  }

  /// Debounce rapid toggles so we reschedule once after the user settles.
  void _scheduleSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (state.enabled) _scheduler.reschedule();
    });
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
