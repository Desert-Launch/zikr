import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/core/services/media/audio_focus.dart';
import 'package:quran/core/services/media/call_interruption.dart';
import 'package:quran/core/services/media/media_artwork.dart';
import 'package:quran/core/services/notifications/notification_window.dart';
import 'package:quran/core/utils/helper/haptics_helper.dart';
import 'package:quran/modules/tasbih/data/datasources/local/ds_hourly_tasbih.dart';
import 'package:quran/modules/tasbih/data/datasources/local/ds_salawat_reminder.dart';
import 'package:quran/modules/tasbih/data/models/m_tasbih_history.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_counter.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_history.dart';
import 'package:quran/modules/tasbih/presentation/cubits/s_tasbih.dart';
import 'package:uuid/uuid.dart';

/// Standalone salawat counter. Reuses the tasbih counter widgets/state but
/// keeps its own persisted record (see [BoxTasbihCounter.salawatKey]) and a
/// single, fixed phrase — no zekr switching. Also owns the salawat reminder
/// schedule (see [DSSalawatReminder]).
class CBSalawat extends Cubit<STasbih> {
  CBSalawat({
    required BoxTasbihCounter counterBox,
    required BoxTasbihHistory historyBox,
    required DSSalawatReminder reminder,
    required DSHourlyTasbih hourly,
    required BoxAppSettings appSettings,
  }) : _counter = counterBox,
       _history = historyBox,
       _reminder = reminder,
       _hourly = hourly,
       _appSettings = appSettings,
       super(const STasbih(target: 100)) {
    _hydrate();
    HapticsHelper.prepare();
  }

  final BoxTasbihCounter _counter;
  final BoxTasbihHistory _history;
  final DSSalawatReminder _reminder;

  /// The hourly zekr shares the reminder window, so a window change has to
  /// rebuild its schedule too — it is the only other feed the window governs.
  final DSHourlyTasbih _hourly;
  final BoxAppSettings _appSettings;
  final _uuid = const Uuid();

  /// The reminder clip, previewable from the settings sheet. Same recording the
  /// notification uses (`res/raw/salah_3la_mohamed.mp3` on Android, its CAF copy
  /// on iOS), so the preview is what the reminder will actually sound like.
  static const String previewAsset = 'assets/audio/salah_3la_mohamed.mp3';

  /// Built on first preview, not in the constructor — this cubit is an eager
  /// app-wide singleton, and most sessions never press play.
  AudioPlayer? _preview;
  StreamSubscription<PlayerState>? _previewSub;

  void _hydrate() {
    final c = _counter.current(BoxTasbihCounter.salawatKey);
    final app = _appSettings.current();
    emit(
      STasbih(
        zekrAr: 'salawat_phrase'.tr(),
        target: c.target,
        count: c.count,
        vibrate: c.vibrate,
        reminderEnabled: c.reminderEnabled,
        reminderIntervalHours: c.reminderIntervalHours,
        reminderHour: c.reminderHour,
        reminderMinute: c.reminderMinute,
        windowStartHour: app.reminderWindowStartHour,
        windowEndHour: app.reminderWindowEndHour,
        ignoreSilent: app.salawatIgnoreSilent,
        pauseOnCall: app.salawatPauseOnCall,
      ),
    );
  }

  Future<void> _persist() async {
    final c = _counter.current(BoxTasbihCounter.salawatKey)
      ..target = state.target
      ..count = state.count
      ..vibrate = state.vibrate
      ..reminderEnabled = state.reminderEnabled
      ..reminderIntervalHours = state.reminderIntervalHours
      ..reminderHour = state.reminderHour
      ..reminderMinute = state.reminderMinute;
    await c.save();
  }

  /// Whether tactile feedback should fire right now.
  ///
  /// [STasbih.pauseOnCall] holds it back while another app owns the audio
  /// session — a call, in practice. Best-effort: audio focus is what an app can
  /// see without READ_PHONE_STATE, so a video call or another media app reads
  /// the same. See [CallInterruption].
  bool get _feedbackAllowed =>
      state.vibrate &&
      !(state.pauseOnCall && CallInterruption.instance.isInterrupted);

  Future<void> tap() async {
    final wasComplete = state.isComplete;
    final next = state.count + 1;
    emit(state.copyWith(count: next));
    if (_feedbackAllowed) {
      HapticsHelper.tick();
    }
    if (!wasComplete && next >= state.target) {
      if (_feedbackAllowed) HapticsHelper.complete();
      await _history.log(
        MTasbihHistory(
          id: _uuid.v4(),
          zekrAr: state.zekrAr,
          count: next,
          completedAt: DateTime.now(),
        ),
      );
    }
    await _persist();
  }

  Future<void> reset() async {
    emit(state.copyWith(count: 0));
    await _persist();
  }

  /// Enables/disables the reminder and reschedules it from current settings.
  Future<void> setReminderEnabled(bool enabled) async {
    emit(state.copyWith(reminderEnabled: enabled));
    await _persist();
    await _reschedule();
  }

  /// Switches to interval mode ([hours] apart, 08:30–22:30) and reschedules.
  Future<void> setReminderInterval(int hours) async {
    emit(state.copyWith(reminderIntervalHours: hours));
    await _persist();
    await _reschedule();
  }

  /// Switches to a single daily reminder at [hour]:[minute] and reschedules.
  Future<void> setReminderTime(int hour, int minute) async {
    emit(
      state.copyWith(
        reminderIntervalHours: 0,
        reminderHour: hour,
        reminderMinute: minute,
      ),
    );
    await _persist();
    await _reschedule();
  }

  /// (a) Route the reminder through the alarm-attributed channel so it sounds
  /// while the phone is silenced.
  ///
  /// Android-only in effect — iOS needs the critical-alert entitlement, which
  /// this app does not hold, so there the switch changes nothing at the OS
  /// level. The reschedule re-points already-pending reminders at the other
  /// channel; both channels are created at boot, so no restart is needed.
  Future<void> setIgnoreSilent(bool value) async {
    emit(state.copyWith(ignoreSilent: value));
    await _appSettings.setSalawatIgnoreSilent(value);
    await _reschedule();
  }

  /// (b) Hold back app-played feedback while a call (or any other app) owns the
  /// audio session. Nothing to reschedule — this is read at fire time.
  Future<void> setPauseOnCall(bool value) async {
    emit(state.copyWith(pauseOnCall: value));
    await _appSettings.setSalawatPauseOnCall(value);
  }

  /// (c) Moves the window the salawat interval reminders and the hourly zekr
  /// fire in. Both feeds are rebuilt, since both read it.
  ///
  /// Deliberately NOT applied to adhan, prayer times, the azkar/quran feed,
  /// khatma or the user's own reminders — a prayer has to fire at its time
  /// whatever hours the user sleeps.
  Future<void> setReminderWindow(int startHour, int endHour) async {
    emit(state.copyWith(windowStartHour: startHour, windowEndHour: endHour));
    await _appSettings.setReminderWindow(
      NotificationWindow(startHour: startHour, endHour: endHour),
    );
    await _reschedule();
    await _hourly.rescheduleFromSettings();
  }

  /// Plays the reminder clip once, or stops it if it is already playing, so the
  /// user can hear the reminder before committing to it.
  ///
  /// Deliberately the in-app player rather than a test notification: the clip is
  /// what is being auditioned, and posting a real notification to preview it
  /// would also have to survive the channel's silent/alarm routing (see
  /// [setIgnoreSilent]) — a different question from "what does it sound like".
  Future<void> togglePreview() async {
    if (state.previewPlaying) {
      await stopPreview();
      return;
    }
    try {
      final player = _preview ??= AudioPlayer();
      if (_previewSub == null) {
        // Registered on first use so the adhan/radio/Qur'an players can stop
        // this preview when they claim the shared background slot.
        AudioFocus.instance.register(this, stopPreview);
        _previewSub = player.playerStateStream.listen((s) {
          if (s.processingState == ProcessingState.completed) {
            unawaited(stopPreview());
          }
        });
      }
      // `just_audio_background` allows one platform-active player app-wide, so
      // free the slot before loading. Every source must carry a MediaItem tag.
      await AudioFocus.instance.take(this);
      await player.setAudioSource(
        AudioSource.asset(
          previewAsset,
          tag: MediaItem(
            id: 'salawat_reminder_preview',
            album: 'salawat_reminder_title'.tr(),
            title: 'salawat_preview_sound'.tr(),
            artUri: MediaArtwork.uri,
          ),
        ),
      );
      await player.seek(Duration.zero);
      if (isClosed) return;
      emit(state.copyWith(previewPlaying: true));
      // Completes when the clip finishes; the stream listener above is what
      // actually clears the flag, since a stop also completes this future.
      await player.play();
    } catch (e, st) {
      AppLogger.error(
        'Salawat preview play',
        error: e,
        stackTrace: st,
        tag: 'CBSalawat',
      );
      if (!isClosed) emit(state.copyWith(previewPlaying: false));
    }
  }

  /// Stops the preview and hands the shared media slot back. Safe to call when
  /// nothing is playing — the sheet calls it unconditionally on close.
  Future<void> stopPreview() async {
    try {
      await _preview?.stop();
    } catch (e) {
      AppLogger.warning('Salawat preview stop failed: $e', tag: 'CBSalawat');
    }
    AudioFocus.instance.release(this);
    if (!isClosed && state.previewPlaying) {
      emit(state.copyWith(previewPlaying: false));
    }
  }

  @override
  Future<void> close() {
    AudioFocus.instance.unregister(this);
    _previewSub?.cancel();
    _preview?.dispose();
    return super.close();
  }

  Future<void> _reschedule() async {
    await _reminder.apply(
      enabled: state.reminderEnabled,
      intervalHours: state.reminderIntervalHours,
      hour: state.reminderHour,
      minute: state.reminderMinute,
    );
  }
}
