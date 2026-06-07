import 'package:equatable/equatable.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_day.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_plan.dart';

class SKhatma extends Equatable {
  const SKhatma({
    this.plan,
    this.metadata,
    this.wirds = const [],
    this.days = const [],
    this.justCompletedId,
    this.isLoading = true,
    this.revision = 0,
  });

  final MKhatmaPlan? plan;
  final MKhatmaMetadata? metadata;
  final List<MKhatmaWird> wirds;
  final List<MKhatmaDay> days;

  /// Set to the completion id right after the user finishes their last day.
  /// The tracker screen reads this to navigate to the congrats screen, then
  /// the field is cleared.
  final String? justCompletedId;
  final bool isLoading;
  final int revision;

  bool get hasActivePlan => plan != null && plan!.isActive;

  int get completedDays => days.where((d) => d.completed).length;

  int get completedToday {
    final now = DateTime.now();
    final key =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    return days.where((d) => d.completed && d.dateKey == key).length;
  }

  MKhatmaWird? get currentWird {
    final current = plan?.currentWirdIndex;
    if (current == null) return null;
    final matches = wirds.where((wird) => wird.index == current);
    return matches.isEmpty ? null : matches.first;
  }

  double get progress {
    final total = wirds.isNotEmpty ? wirds.length : (plan?.totalDays ?? 0);
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
    MKhatmaMetadata? metadata,
    bool clearMetadata = false,
    List<MKhatmaWird>? wirds,
    List<MKhatmaDay>? days,
    String? justCompletedId,
    bool clearJustCompleted = false,
    bool? isLoading,
    int? revision,
  }) {
    return SKhatma(
      plan: clearPlan ? null : (plan ?? this.plan),
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
      wirds: wirds ?? this.wirds,
      days: days ?? this.days,
      justCompletedId: clearJustCompleted
          ? null
          : (justCompletedId ?? this.justCompletedId),
      isLoading: isLoading ?? this.isLoading,
      revision: revision ?? this.revision,
    );
  }

  @override
  List<Object?> get props => [
    plan?.planId,
    plan?.isActive,
    plan?.currentWirdIndex,
    plan?.reminderEnabled,
    plan?.reminderHour,
    plan?.reminderMinute,
    metadata,
    wirds,
    days,
    justCompletedId,
    isLoading,
    revision,
  ];
}
