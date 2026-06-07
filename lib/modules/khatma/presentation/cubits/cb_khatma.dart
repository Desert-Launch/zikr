import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/core/services/notifications/notification_channels.dart';
import 'package:quran/core/services/notifications/notification_payload.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/modules/khatma/data/datasources/local/ds_local_khatma.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_completion.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_day.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_plan.dart';
import 'package:quran/modules/khatma/data/sources/local/box_khatma_completion.dart';
import 'package:quran/modules/khatma/data/sources/local/box_khatma_day.dart';
import 'package:quran/modules/khatma/data/sources/local/box_khatma_plan.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';
import 'package:uuid/uuid.dart';

class CBKhatma extends Cubit<SKhatma> {
  CBKhatma({
    required BoxKhatmaPlan planBox,
    required BoxKhatmaDay dayBox,
    required BoxKhatmaCompletion completionBox,
    required DSLocalKhatma local,
    required NotificationsService notifications,
  }) : _plan = planBox,
       _days = dayBox,
       _completion = completionBox,
       _local = local,
       _notifications = notifications,
       super(const SKhatma()) {
    hydrate();
  }

  static const _notificationId = 6000;

  final BoxKhatmaPlan _plan;
  final BoxKhatmaDay _days;
  final BoxKhatmaCompletion _completion;
  final DSLocalKhatma _local;
  final NotificationsService _notifications;
  final _uuid = const Uuid();

  Future<void> hydrate() async {
    final plan = _plan.current();
    if (plan == null || !plan.isActive) {
      emit(
        state.copyWith(
          clearPlan: true,
          clearMetadata: true,
          wirds: const [],
          days: _days.all(),
          isLoading: false,
        ),
      );
      return;
    }

    var metadata = plan.planId > 0 ? await _local.plan(plan.planId) : null;
    metadata ??= await _local.planForDays(plan.totalDays);
    if (metadata == null) {
      await cancelPlan();
      return;
    }
    if (plan.planId == 0) {
      plan
        ..planId = metadata.id
        ..currentWirdIndex = _days.completedCount + 1;
      await _plan.save(plan);
    }
    final wirds = await _local.wirds(metadata);
    emit(
      state.copyWith(
        plan: plan,
        metadata: metadata,
        wirds: wirds,
        days: _days.all(),
        isLoading: false,
      ),
    );
    if (plan.reminderEnabled) await _scheduleReminder(plan);
  }

  Future<void> startPlan(MKhatmaMetadata metadata) async {
    final plan = MKhatmaPlan(
      totalDays: metadata.days,
      startedAt: DateTime.now(),
      planId: metadata.id,
    );
    await _plan.save(plan);
    await _days.clearAll();
    final wirds = await _local.wirds(metadata);
    emit(
      state.copyWith(
        plan: plan,
        metadata: metadata,
        wirds: wirds,
        days: const [],
        clearJustCompleted: true,
        isLoading: false,
      ),
    );
    await _scheduleReminder(plan);
  }

  Future<void> completeCurrentWird() async {
    final plan = state.plan;
    final wird = state.currentWird;
    if (plan == null || wird == null || !plan.isActive) return;
    final now = DateTime.now();
    final day = MKhatmaDay(
      dateKey: BoxKhatmaDay.keyFor(now),
      dayIndex: wird.index,
      targetPages: wird.pageCount,
      pagesRead: wird.pageCount,
      completed: true,
      completedAt: now,
    );
    await _days.upsertWird(day);
    plan.currentWirdIndex = wird.index + 1;
    await _plan.save(plan);
    final updatedDays = _days.all();
    emit(
      state.copyWith(
        plan: plan,
        days: updatedDays,
        revision: state.revision + 1,
      ),
    );
    if (plan.currentWirdIndex > state.wirds.length) await _finalize();
  }

  Future<void> setReminderEnabled(bool enabled) async {
    final plan = state.plan;
    if (plan == null) return;
    plan.reminderEnabled = enabled;
    await _plan.save(plan);
    emit(state.copyWith(plan: plan, revision: state.revision + 1));
    if (enabled) {
      await _scheduleReminder(plan);
    } else {
      await _notifications.cancel(_notificationId);
    }
  }

  Future<void> setReminderTime(int hour, int minute) async {
    final plan = state.plan;
    if (plan == null) return;
    plan
      ..reminderHour = hour
      ..reminderMinute = minute;
    await _plan.save(plan);
    emit(state.copyWith(plan: plan, revision: state.revision + 1));
    if (plan.reminderEnabled) await _scheduleReminder(plan);
  }

  Future<void> _scheduleReminder(MKhatmaPlan plan) async {
    await _notifications.init();
    final hasPermission = await _notifications.hasPermission();
    if (!hasPermission) {
      final granted = await _notifications.requestPermission();
      if (!granted) return;
    }
    await _notifications.cancel(_notificationId);
    await _notifications.scheduleDaily(
      id: _notificationId,
      hour: plan.reminderHour,
      minute: plan.reminderMinute,
      title: 'ورد الختمة اليومي',
      body: 'حان وقت قراءة وردك اليومي',
      channel: AppNotificationChannels.quranReminders,
      payload: const NotificationPayload(type: 'khatma'),
    );
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
    await _notifications.cancel(_notificationId);
    emit(
      state.copyWith(
        plan: plan,
        justCompletedId: completion.id,
        revision: state.revision + 1,
      ),
    );
  }

  void acknowledgeCompletion() {
    emit(state.copyWith(clearJustCompleted: true));
  }

  Future<void> cancelPlan() async {
    await _plan.clear();
    await _days.clearAll();
    await _notifications.cancel(_notificationId);
    emit(
      state.copyWith(
        clearPlan: true,
        clearMetadata: true,
        wirds: const [],
        days: const [],
        isLoading: false,
      ),
    );
  }

  List<MKhatmaCompletion> history() => _completion.all();

  int _computeLongestStreak() {
    final dates =
        state.days
            .where((day) => day.completed)
            .map((day) => day.dateKey)
            .toSet()
            .toList()
          ..sort();
    if (dates.isEmpty) return 0;
    var best = 1;
    var run = 1;
    for (var i = 1; i < dates.length; i++) {
      final previous = _parseDateKey(dates[i - 1]);
      final current = _parseDateKey(dates[i]);
      if (current.difference(previous).inDays == 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return best;
  }

  DateTime _parseDateKey(String key) {
    return DateTime(
      int.parse(key.substring(0, 4)),
      int.parse(key.substring(4, 6)),
      int.parse(key.substring(6, 8)),
    );
  }
}
