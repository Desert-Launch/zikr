import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/tasbih/data/datasources/local/ds_hourly_tasbih.dart';

import 'package:quran/modules/tasbih/data/models/m_tasbih_history.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_counter.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_history.dart';
import 'package:quran/modules/tasbih/presentation/cubits/s_tasbih.dart';
import 'package:uuid/uuid.dart';
import 'package:vibration/vibration.dart';

/// App-wide tasbih singleton. Lives in AppModule because the hourly toggle
/// (in Settings) writes the same state the counter screen reads.
class CBTasbih extends Cubit<STasbih> {
  CBTasbih({
    required BoxTasbihCounter counterBox,
    required BoxTasbihHistory historyBox,
    required DSHourlyTasbih hourly,
  })  : _counter = counterBox,
        _history = historyBox,
        _hourly = hourly,
        super(const STasbih()) {
    _hydrate();
    _initVibrator();
  }

  final BoxTasbihCounter _counter;
  final BoxTasbihHistory _history;
  final DSHourlyTasbih _hourly;
  final _uuid = const Uuid();

  /// Whether the device has a vibration motor — checked once so the
  /// target-complete pulse can fall back to haptics when it doesn't.
  bool _hasVibrator = false;

  Future<void> _initVibrator() async {
    try {
      _hasVibrator = await Vibration.hasVibrator();
    } catch (_) {
      _hasVibrator = false;
    }
  }

  void _hydrate() {
    final c = _counter.current();
    emit(STasbih(
      zekrAr: c.zekrAr,
      target: c.target,
      count: c.count,
      vibrate: c.vibrate,
      hourlyEnabled: c.hourlyEnabled,
    ));
  }

  Future<void> _persist() async {
    final c = _counter.current()
      ..zekrAr = state.zekrAr
      ..target = state.target
      ..count = state.count
      ..vibrate = state.vibrate
      ..hourlyEnabled = state.hourlyEnabled;
    await c.save();
  }

  Future<void> tap() async {
    final wasComplete = state.isComplete;
    final next = state.count + 1;
    emit(state.copyWith(count: next));
    if (state.vibrate) {
      HapticFeedback.lightImpact();
    }
    // When we hit the target this tap, log the session and pulse harder.
    if (!wasComplete && next >= state.target) {
      if (state.vibrate) _pulseComplete();
      await _history.log(MTasbihHistory(
        id: _uuid.v4(),
        zekrAr: state.zekrAr,
        count: next,
        completedAt: DateTime.now(),
      ));
    }
    await _persist();
  }

  /// Distinct double-buzz when the target is reached — falls back to a heavy
  /// haptic on devices without amplitude/pattern support.
  void _pulseComplete() {
    if (_hasVibrator) {
      Vibration.vibrate(pattern: const [0, 200, 100, 300]);
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> reset() async {
    emit(state.copyWith(count: 0));
    await _persist();
  }

  Future<void> setZekr(String zekrAr) async {
    emit(state.copyWith(zekrAr: zekrAr, count: 0));
    await _persist();
  }

  Future<void> setTarget(int target) async {
    emit(state.copyWith(target: target));
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
}
