import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
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
  })  : _counter = counterBox,
        _history = historyBox,
        _reminder = reminder,
        super(const STasbih(target: 100)) {
    _hydrate();
  }

  final BoxTasbihCounter _counter;
  final BoxTasbihHistory _history;
  final DSSalawatReminder _reminder;
  final _uuid = const Uuid();

  void _hydrate() {
    final c = _counter.current(BoxTasbihCounter.salawatKey);
    emit(STasbih(
      zekrAr: 'salawat_phrase'.tr(),
      target: c.target,
      count: c.count,
      vibrate: c.vibrate,
      reminderEnabled: c.reminderEnabled,
      reminderIntervalHours: c.reminderIntervalHours,
      reminderHour: c.reminderHour,
      reminderMinute: c.reminderMinute,
    ));
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

  Future<void> tap() async {
    final wasComplete = state.isComplete;
    final next = state.count + 1;
    emit(state.copyWith(count: next));
    if (state.vibrate) {
      HapticFeedback.lightImpact();
    }
    if (!wasComplete && next >= state.target) {
      if (state.vibrate) HapticFeedback.mediumImpact();
      await _history.log(MTasbihHistory(
        id: _uuid.v4(),
        zekrAr: state.zekrAr,
        count: next,
        completedAt: DateTime.now(),
      ));
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
    emit(state.copyWith(
      reminderIntervalHours: 0,
      reminderHour: hour,
      reminderMinute: minute,
    ));
    await _persist();
    await _reschedule();
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
