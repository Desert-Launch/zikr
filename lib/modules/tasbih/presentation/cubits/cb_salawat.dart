import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/tasbih/data/models/m_tasbih_history.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_counter.dart';
import 'package:quran/modules/tasbih/data/sources/local/box_tasbih_history.dart';
import 'package:quran/modules/tasbih/presentation/cubits/s_tasbih.dart';
import 'package:uuid/uuid.dart';

/// Standalone salawat counter. Reuses the tasbih counter widgets/state but
/// keeps its own persisted record (see [BoxTasbihCounter.salawatKey]) and a
/// single, fixed phrase — no zekr switching.
class CBSalawat extends Cubit<STasbih> {
  CBSalawat({
    required BoxTasbihCounter counterBox,
    required BoxTasbihHistory historyBox,
  })  : _counter = counterBox,
        _history = historyBox,
        super(const STasbih(target: 100)) {
    _hydrate();
  }

  final BoxTasbihCounter _counter;
  final BoxTasbihHistory _history;
  final _uuid = const Uuid();

  void _hydrate() {
    final c = _counter.current(BoxTasbihCounter.salawatKey);
    emit(STasbih(
      zekrAr: 'salawat_phrase'.tr(),
      target: c.target,
      count: c.count,
      vibrate: c.vibrate,
    ));
  }

  Future<void> _persist() async {
    final c = _counter.current(BoxTasbihCounter.salawatKey)
      ..target = state.target
      ..count = state.count
      ..vibrate = state.vibrate;
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
}
