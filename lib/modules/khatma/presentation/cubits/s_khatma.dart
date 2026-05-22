import 'package:equatable/equatable.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_day.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_plan.dart';

class SKhatma extends Equatable {
  const SKhatma({
    this.plan,
    this.days = const [],
    this.justCompletedId,
  });

  final MKhatmaPlan? plan;
  final List<MKhatmaDay> days;
  /// Set to the completion id right after the user finishes their last day.
  /// The tracker screen reads this to navigate to the congrats screen, then
  /// the field is cleared.
  final String? justCompletedId;

  bool get hasActivePlan => plan != null && plan!.isActive;

  int get completedDays => days.where((d) => d.completed).length;

  double get progress {
    final total = plan?.totalDays ?? 0;
    if (total == 0) return 0;
    return (completedDays / total).clamp(0.0, 1.0);
  }

  MKhatmaDay? get today {
    final now = DateTime.now();
    final yyyy = now.year.toString().padLeft(4, '0');
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final key = '$yyyy$mm$dd';
    final hits = days.where((d) => d.dateKey == key);
    return hits.isEmpty ? null : hits.first;
  }

  SKhatma copyWith({
    MKhatmaPlan? plan,
    bool clearPlan = false,
    List<MKhatmaDay>? days,
    String? justCompletedId,
    bool clearJustCompleted = false,
  }) {
    return SKhatma(
      plan: clearPlan ? null : (plan ?? this.plan),
      days: days ?? this.days,
      justCompletedId: clearJustCompleted
          ? null
          : (justCompletedId ?? this.justCompletedId),
    );
  }

  @override
  List<Object?> get props => [plan?.totalDays, plan?.isActive, days, justCompletedId];
}
