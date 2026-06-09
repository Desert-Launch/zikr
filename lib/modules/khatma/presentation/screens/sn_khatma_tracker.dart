import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/modules/khatma/presentation/cubits/cb_khatma.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';

class SNKhatmaTracker extends StatelessWidget {
  const SNKhatmaTracker({super.key});

  static const _green = Color(0xFF007A58);
  static const _canvas = Color(0xFFF8F7F4);
  static const _border = Color(0xFFDDE6E0);

  @override
  Widget build(BuildContext context) {
    final cubit = Modular.get<CBKhatma>();
    return BlocProvider.value(
      value: cubit,
      child: BlocConsumer<CBKhatma, SKhatma>(
        listenWhen: (previous, current) =>
            previous.justCompletedId != current.justCompletedId,
        listener: (_, state) {
          if (state.justCompletedId == null) return;
          cubit.acknowledgeCompletion();
          Modular.to.pushReplacementNamed(KhatmaRoutes.fullCompleted());
        },
        builder: (_, state) {
          if (state.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!state.hasActivePlan || state.currentWird == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Modular.to.pushReplacementNamed(KhatmaRoutes.fullPlans());
            });
            return const Scaffold(body: SizedBox.shrink());
          }
          return Scaffold(
            backgroundColor: _canvas,
            body: ListView(
              padding: EdgeInsets.zero,
              children: [
                WGradientAppBar(title: 'khatma_wird_title'.tr()),
                Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 28.h),
                  child: Column(
                    children: [
                      _CurrentWirdCard(state: state),
                      SizedBox(height: 12.h),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28.r),
                            ),
                          ),
                          onPressed: () => _complete(context, cubit, state),
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: Text('khatma_complete_wird'.tr()),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _SectionLabel('khatma_reminder'.tr()),
                      _ReminderCard(cubit: cubit, state: state),
                      SizedBox(height: 16.h),
                      _SectionLabel('khatma_current_plan'.tr()),
                      _ProgressCard(state: state),
                      SizedBox(height: 12.h),
                      _PlanCard(state: state),
                      SizedBox(height: 12.h),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: _border),
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: () => _cancel(context, cubit),
                          child: Text('khatma_cancel_plan'.tr()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _complete(
    BuildContext context,
    CBKhatma cubit,
    SKhatma state,
  ) async {
    if (state.completedToday > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('khatma_second_today_warning_title'.tr()),
          content: Text('khatma_second_today_warning_body'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('common_cancel'.tr()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('khatma_continue_completion'.tr()),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await cubit.completeCurrentWird();
  }

  Future<void> _cancel(BuildContext context, CBKhatma cubit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('khatma_cancel_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('common_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'common_delete'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await cubit.cancelPlan();
    Modular.to.pushReplacementNamed(KhatmaRoutes.fullPlans());
  }
}

class _CurrentWirdCard extends StatelessWidget {
  const _CurrentWirdCard({required this.state});

  final SKhatma state;

  @override
  Widget build(BuildContext context) {
    final wird = state.currentWird!;
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    final startSurah = isArabic ? wird.startSurahAr : wird.startSurahEn;
    final endSurah = isArabic ? wird.endSurahAr : wird.endSurahEn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(end: 5.w, bottom: 6.h),
          child: Text(
            '${'khatma_wird_day'.tr()} ${wird.index}',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: SNKhatmaTracker._border),
          ),
          child: Column(
            children: [
              _RangeRow(
                title: '${'khatma_from'.tr()} $startSurah',
                subtitle: '${'khatma_ayah'.tr()} ${wird.startAyahNumber}',
                pageNumber: wird.startPageNumber,
              ),
              const Divider(height: 1),
              _RangeRow(
                title: '${'khatma_to'.tr()} $endSurah',
                subtitle: '${'khatma_ayah'.tr()} ${wird.endAyahNumber}',
                pageNumber: wird.endPageNumber,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RangeRow extends StatelessWidget {
  const _RangeRow({
    required this.title,
    required this.subtitle,
    required this.pageNumber,
  });

  final String title;
  final String subtitle;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Modular.to.pushNamed(QuranRoutes.readerFromPage(pageNumber)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            const Icon(Icons.chevron_left_rounded, size: 22),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, style: TextStyle(fontSize: 15.sp)),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({required this.cubit, required this.state});

  final CBKhatma cubit;
  final SKhatma state;

  @override
  Widget build(BuildContext context) {
    final plan = state.plan!;
    final time = TimeOfDay(
      hour: plan.reminderHour,
      minute: plan.reminderMinute,
    );
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SNKhatmaTracker._border),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: plan.reminderEnabled,
            activeTrackColor: SNKhatmaTracker._green,
            title: Text(
              'khatma_daily_wird'.tr(),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 15.sp),
            ),
            subtitle: Text(
              time.format(context),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            onChanged: cubit.setReminderEnabled,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.access_time_rounded,
              color: SNKhatmaTracker._green,
            ),
            title: Text(
              'khatma_reminder_time'.tr(),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 15.sp),
            ),
            subtitle: Text(
              time.format(context),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (picked != null) {
                await cubit.setReminderTime(picked.hour, picked.minute);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.state});

  final SKhatma state;

  @override
  Widget build(BuildContext context) {
    final remaining = state.wirds.length - state.completedDays;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SNKhatmaTracker._border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34.r,
                height: 34.r,
                decoration: const BoxDecoration(
                  color: SNKhatmaTracker._green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'khatma_current_plan'.tr(),
                    style: TextStyle(fontSize: 17.sp),
                  ),
                  Text(
                    'khatma_remaining_wirds'.tr().replaceFirst(
                      '{{n}}',
                      '$remaining',
                    ),
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 4.h,
              backgroundColor: const Color(0xFFE8E2BF),
              color: SNKhatmaTracker._green,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.state});

  final SKhatma state;

  @override
  Widget build(BuildContext context) {
    final metadata = state.metadata!;
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: SNKhatmaTracker._border),
      ),
      child: Row(
        children: [
          Text(
            '${state.completedDays} / ${state.wirds.length}',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            isArabic ? metadata.nameAr : metadata.nameEn,
            style: TextStyle(fontSize: 15.sp),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: 5.w, bottom: 6.h),
        child: Text(
          text,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        ),
      ),
    );
  }
}
