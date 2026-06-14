import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/modules/adhan/data/datasources/local/ds_local_adhan.dart';
import 'package:quran/modules/adhan/data/models/m_adhan_settings.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_preference.dart';
import 'package:quran/modules/adhan/data/sources/local/box_adhan_settings.dart';
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
  }) : _adhanSettings = adhanSettings,
       _prayerSettings = prayerSettings,
       _adhanPrefs = adhanPrefs,
       _local = local,
       _notifications = notifications,
       _scheduler = scheduler,
       super(const SAdhanSettings()) {
    load();
  }

  final BoxAdhanSettings _adhanSettings;
  final BoxPrayerSettings _prayerSettings;
  final BoxAdhanPreference _adhanPrefs;
  final DSLocalAdhan _local;
  final NotificationsService _notifications;
  final AdhanScheduler _scheduler;

  Timer? _debounce;

  Future<void> load() async {
    final s = _adhanSettings.current();
    final p = _prayerSettings.current();
    final hasPerm = await _notifications.hasPermission();
    final voiceName = await _selectedVoiceName();
    final voices = await _prayerVoices(p.adhanIdPerPrayer ?? const {});
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
