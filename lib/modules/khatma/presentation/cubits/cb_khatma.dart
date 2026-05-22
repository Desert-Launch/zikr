import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_completion.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_day.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_plan.dart';
import 'package:quran/modules/khatma/data/sources/local/box_khatma_completion.dart';
import 'package:quran/modules/khatma/data/sources/local/box_khatma_day.dart';
import 'package:quran/modules/khatma/data/sources/local/box_khatma_plan.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';
import 'package:uuid/uuid.dart';

/// App-wide khatma singleton. Plan + day-records live in their own boxes;
/// this cubit just orchestrates updates and emits the merged state.
class CBKhatma extends Cubit<SKhatma> {
  CBKhatma({
    required BoxKhatmaPlan planBox,
    required BoxKhatmaDay dayBox,
    required BoxKhatmaCompletion completionBox,
  })  : _plan = planBox,
        _days = dayBox,
        _completion = completionBox,
        super(const SKhatma()) {
    _hydrate();
  }

  final BoxKhatmaPlan _plan;
  final BoxKhatmaDay _days;
  final BoxKhatmaCompletion _completion;
  final _uuid = const Uuid();

  void _hydrate() {
    emit(state.copyWith(plan: _plan.current(), days: _days.all()));
  }

  Future<void> startPlan(int totalDays) async {
    if (totalDays <= 0) return;
    final plan = MKhatmaPlan(
      totalDays: totalDays,
      startedAt: DateTime.now(),
      isActive: true,
    );
    await _plan.save(plan);
    await _days.clearAll();
    emit(state.copyWith(plan: plan, days: const [], clearJustCompleted: true));
  }

  /// Check today off. If this is the final day in the plan, also record a
  /// completion + set [justCompletedId] so the UI can route to the congrats
  /// screen.
  Future<void> markTodayDone() async {
    final plan = state.plan;
    if (plan == null || !plan.isActive) return;
    final now = DateTime.now();
    final key = BoxKhatmaDay.keyFor(now);
    final existing = _days.today();
    if (existing != null && existing.completed) return;

    final dayIndex = existing?.dayIndex ?? (state.days.length + 1);
    final day = existing ??
        MKhatmaDay(
          dateKey: key,
          dayIndex: dayIndex,
          targetPages: plan.pagesPerDay,
        );
    day
      ..pagesRead = plan.pagesPerDay
      ..completed = true
      ..completedAt = now;
    await _days.upsert(day);

    final updatedDays = _days.all();
    emit(state.copyWith(days: updatedDays));

    if (updatedDays.where((d) => d.completed).length >= plan.totalDays) {
      await _finalize();
    }
  }

  Future<void> _finalize() async {
    final plan = state.plan;
    if (plan == null) return;
    final completion = MKhatmaCompletion(
      id: _uuid.v4(),
      planTotalDays: plan.totalDays,
      startedAt: plan.startedAt,
      completedAt: DateTime.now(),
      daysCompleted: state.completedDays,
      longestStreakDays: _computeLongestStreak(),
    );
    await _completion.record(completion);
    plan.isActive = false;
    await _plan.save(plan);
    emit(state.copyWith(plan: plan, justCompletedId: completion.id));
  }

  void acknowledgeCompletion() {
    emit(state.copyWith(clearJustCompleted: true));
  }

  Future<void> cancelPlan() async {
    await _plan.clear();
    await _days.clearAll();
    emit(state.copyWith(clearPlan: true, days: const []));
  }

  List<MKhatmaCompletion> history() => _completion.all();

  int _computeLongestStreak() {
    final completed = state.days.where((d) => d.completed).toList()
      ..sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
    if (completed.isEmpty) return 0;
    int best = 1;
    int run = 1;
    for (int i = 1; i < completed.length; i++) {
      if (completed[i].dayIndex == completed[i - 1].dayIndex + 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return best;
  }
}
