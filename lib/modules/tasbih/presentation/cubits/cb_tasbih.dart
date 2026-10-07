import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/notifications/hourly_rotation.dart';
import 'package:quran/core/services/notifications/notification_window.dart';
import 'package:quran/core/utils/helper/day_change_watcher.dart';
import 'package:quran/core/utils/helper/haptics_helper.dart';
import 'package:quran/modules/tasbih/data/datasources/local/ds_hourly_tasbih.dart';

import 'package:quran/modules/tasbih/data/models/m_tasbih_history.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_counter.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_history.dart';
import 'package:quran/modules/tasbih/presentation/cubits/s_tasbih.dart';
import 'package:uuid/uuid.dart';

/// App-wide tasbih singleton. Lives in AppModule because the hourly toggle
/// (in Settings) writes the same state the counter screen reads.
class CBTasbih extends Cubit<STasbih> {
  CBTasbih({
    required BoxTasbihCounter counterBox,
    required BoxTasbihHistory historyBox,
    required DSHourlyTasbih hourly,
    required BoxAppSettings appSettings,
  })  : _counter = counterBox,
        _history = historyBox,
        _hourly = hourly,
        _appSettings = appSettings,
        super(const STasbih()) {
    _hydrate();
    unawaited(_loadZikrCount());
    HapticsHelper.prepare();
    _dayWatcher = DayChangeWatcher(_syncToday);
  }

  final BoxTasbihCounter _counter;
  final BoxTasbihHistory _history;
  final DSHourlyTasbih _hourly;
  final BoxAppSettings _appSettings;
  final _uuid = const Uuid();
  late final DayChangeWatcher _dayWatcher;

  void _hydrate() {
    final c = _counter.today();
    final app = _appSettings.current();
    emit(STasbih(
      zekrAr: c.zekrAr,
      target: c.target,
      count: _todayCount(zekrAr: c.zekrAr, target: c.target),
      vibrate: c.vibrate,
      hourlyEnabled: c.hourlyEnabled,
      hourlyZikrSound: app.hourlyZikrSound,
      hourlyZikrVolume: app.hourlyZikrVolume,
      hourlyStartHour: app.hourlyWindowStartHour,
      hourlyEndHour: app.hourlyWindowEndHour,
    ));
  }

  /// The azkar live in a bundled JSON, so their count arrives a beat after the
  /// rest of the state.
  Future<void> _loadZikrCount() async {
    final count = await _hourly.zikrCount();
    if (!isClosed) emit(state.copyWith(hourlyZikrCount: count));
  }

  /// Brings the on-screen count in line with today's tally. Taps already read
  /// the box, so this is only about the number shown: without it, a screen
  /// left open overnight (or an app resumed next morning) keeps showing
  /// yesterday's count until the first tap.
  void _syncToday() {
    if (isClosed) return;
    final count = _todayCount();
    if (count != state.count) emit(state.copyWith(count: count));
  }

  Future<void> _persist() async {
    final c = _counter.current()
      ..zekrAr = state.zekrAr
      ..target = state.target
      ..vibrate = state.vibrate
      ..hourlyEnabled = state.hourlyEnabled;
    await c.save();
  }

  /// Today's tally for [zekrAr] (the active phrase by default), never above
  /// [target] — a count taken under a bigger target shows as complete once the
  /// target is lowered, and comes back in full if it's raised again. Read from
  /// the box rather than from state so a session left open across midnight
  /// sees the wipe instead of carrying yesterday's count forward.
  int _todayCount({String? zekrAr, int? target}) {
    final stored = _counter.today().phraseCounts[zekrAr ?? state.zekrAr] ?? 0;
    return min(stored, target ?? state.target);
  }

  Future<void> _saveCount(int count) async {
    final c = _counter.today();
    c.phraseCounts[state.zekrAr] = count;
    await c.save();
  }

  /// One bead. Stops at the target — once the round is complete further taps
  /// are ignored until the user resets or switches phrase.
  Future<void> tap() async {
    final count = _todayCount();
    if (count >= state.target) return;
    final next = count + 1;
    emit(state.copyWith(count: next));
    if (state.vibrate) {
      HapticsHelper.tick();
    }
    // Written before anything yields, so a tap landing while the completion
    // below is still logging reads this count rather than the one before it.
    final saved = _saveCount(next);
    // When we hit the target this tap, log the session and pulse harder.
    if (next >= state.target) {
      if (state.vibrate) HapticsHelper.complete();
      await _history.log(MTasbihHistory(
        id: _uuid.v4(),
        zekrAr: state.zekrAr,
        count: next,
        completedAt: DateTime.now(),
      ));
    }
    await saved;
  }

  Future<void> reset() async {
    emit(state.copyWith(count: 0));
    await _saveCount(0);
  }

  /// Switches the phrase and resumes its own count for today — each phrase
  /// keeps a separate tally, so flipping between them never loses progress.
  Future<void> setZekr(String zekrAr) async {
    emit(state.copyWith(zekrAr: zekrAr, count: _todayCount(zekrAr: zekrAr)));
    await _persist();
  }

  /// Changing the target re-caps the count: dropping below what's already
  /// been counted lands on "complete" rather than a number past the target.
  Future<void> setTarget(int target) async {
    emit(state.copyWith(target: target, count: _todayCount(target: target)));
    await _persist();
  }

  Future<void> setVibrate(bool value) async {
    emit(state.copyWith(vibrate: value));
    await _persist();
  }

  Future<void> setHourlyEnabled(bool enabled) async {
    emit(state.copyWith(hourlyEnabled: enabled));
    await _persist();
    if (enabled) {
      await _hourly.enable();
    } else {
      await _hourly.disable();
    }
  }

  /// Switches the hourly zekr between its own recordings and the device's
  /// default (silent) notification sound.
  ///
  /// Muting a channel isn't an option — Android freezes a channel's sound when
  /// it creates it, so the two modes are two different sets of channels and the
  /// whole feed has to be re-armed onto the other set. Hence the reschedule
  /// rather than a plain flag write.
  ///
  /// Lives on [BoxAppSettings] rather than the tasbih counter because
  /// `DSHourlyTasbih` reads it while scheduling, on the boot path, long before
  /// this cubit exists.
  Future<void> setHourlyZikrSound(bool value) async {
    emit(state.copyWith(hourlyZikrSound: value));
    await _appSettings.setHourlyZikrSound(value);
    await _hourly.rescheduleFromSettings();
  }

  /// Moves the hourly zekr's range and re-arms the feed.
  ///
  /// Also restarts the rotation: the range the user is in, or about to enter,
  /// becomes day 1 and opens on the first zekr — see
  /// [HourlyRotation.currentWindowDay].
  Future<void> setHourlyWindow(int startHour, int endHour) async {
    final window = NotificationWindow(
      startHour: startHour % 24,
      endHour: endHour % 24,
    );
    emit(state.copyWith(
      hourlyStartHour: window.startHour,
      hourlyEndHour: window.endHour,
    ));
    final dayOne = HourlyRotation.currentWindowDay(window, DateTime.now());
    await _appSettings.setHourlyWindow(
      window,
      rotationAnchorDay: HourlyRotation.epochDay(dayOne),
    );
    await _hourly.rescheduleFromSettings();
  }

  /// Sets the hourly zekr's loudness (0–100) and re-arms the feed — on Android
  /// the level is baked into each armed clip. See [MAppSettings.hourlyZikrVolume].
  Future<void> setHourlyZikrVolume(int value) async {
    final clamped = value.clamp(0, 100);
    if (clamped == state.hourlyZikrVolume) return;
    emit(state.copyWith(hourlyZikrVolume: clamped));
    await _appSettings.setHourlyZikrVolume(clamped);
    await _hourly.rescheduleFromSettings();
  }

  @override
  Future<void> close() {
    _dayWatcher.dispose();
    return super.close();
  }
}
