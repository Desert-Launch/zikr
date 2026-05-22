import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/khatma/presentation/cubits/cb_khatma.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';

class SNKhatmaTracker extends StatelessWidget {
  const SNKhatmaTracker({super.key});

  @override
  Widget build(BuildContext context) {
    final cb = Modular.get<CBKhatma>();
    return BlocProvider.value(
      value: cb,
      child: Scaffold(
        appBar: AppBar(
          title: Text('khatma_title'.tr(),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'common_cancel'.tr(),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('khatma_cancel_confirm'.tr()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('common_cancel'.tr()),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColorsLight.error,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('common_delete'.tr()),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await cb.cancelPlan();
                  if (!context.mounted) return;
                  Modular.to.pushReplacementNamed(KhatmaRoutes.fullPlans());
                }
              },
            ),
          ],
        ),
        body: BlocConsumer<CBKhatma, SKhatma>(
          listenWhen: (a, b) => a.justCompletedId != b.justCompletedId,
          listener: (context, state) {
            if (state.justCompletedId != null) {
              cb.acknowledgeCompletion();
              Modular.to.pushReplacementNamed(KhatmaRoutes.fullCompleted());
            }
          },
          builder: (context, state) {
            final plan = state.plan;
            if (plan == null) return const SizedBox.shrink();
            final today = state.today;
            return ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _Hero(state: state),
                SizedBox(height: 14.h),
                _TodayCard(
                  pagesTarget: plan.pagesPerDay,
                  pagesDone: today?.pagesRead ?? 0,
                  completed: today?.completed ?? false,
                  onMarkDone: cb.markTodayDone,
                ),
                SizedBox(height: 18.h),
                Text('khatma_days_grid'.tr(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.brand.muted,
                      fontWeight: FontWeight.w700,
                    )),
                SizedBox(height: 6.h),
                _DaysGrid(totalDays: plan.totalDays, completed: state.days),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.state});
  final SKhatma state;

  @override
  Widget build(BuildContext context) {
    final plan = state.plan!;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColorsLight.primary, AppColorsLight.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('khatma_progress'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12.sp,
              )),
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${state.completedDays}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40.sp,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
              SizedBox(width: 6.w),
              Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Text('/ ${plan.totalDays} ${'khatma_days_unit'.tr()}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14.sp,
                    )),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: state.progress,
              minHeight: 8.h,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              color: AppColorsLight.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.pagesTarget,
    required this.pagesDone,
    required this.completed,
    required this.onMarkDone,
  });
  final int pagesTarget;
  final int pagesDone;
  final bool completed;
  final VoidCallback onMarkDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.brand.surface,
        border: Border.all(color: context.brand.border),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('khatma_today'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                color: context.brand.muted,
                fontWeight: FontWeight.w700,
              )),
          SizedBox(height: 4.h),
          Text(
            'khatma_today_target'.tr().replaceFirst('{{n}}', '$pagesTarget'),
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 12.h),
          if (completed)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColorsLight.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColorsLight.success, size: 18.r),
                  SizedBox(width: 8.w),
                  Text('khatma_today_done'.tr(),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColorsLight.success,
                      )),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check_rounded),
                label: Text('khatma_mark_done'.tr()),
                onPressed: onMarkDone,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColorsLight.primary,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
              ),
            ),
          if (pagesDone > 0 && !completed) ...[
            SizedBox(height: 8.h),
            Text(
              'khatma_pages_done'
                  .tr()
                  .replaceFirst('{{done}}', '$pagesDone')
                  .replaceFirst('{{target}}', '$pagesTarget'),
              style: TextStyle(fontSize: 11.sp, color: context.brand.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _DaysGrid extends StatelessWidget {
  const _DaysGrid({required this.totalDays, required this.completed});
  final int totalDays;
  final List<dynamic> completed;

  @override
  Widget build(BuildContext context) {
    final completedIndices = <int>{
      for (final d in completed)
        if (d.completed == true) d.dayIndex as int,
    };
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalDays,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 6.h,
        crossAxisSpacing: 6.w,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (_, i) {
        final dayIndex = i + 1;
        final done = completedIndices.contains(dayIndex);
        return Container(
          decoration: BoxDecoration(
            color: done
                ? AppColorsLight.primary
                : context.brand.surface,
            border: Border.all(
              color: done ? AppColorsLight.primary : context.brand.border,
            ),
            borderRadius: BorderRadius.circular(6.r),
          ),
          alignment: Alignment.center,
          child: Text(
            '$dayIndex',
            style: GoogleFonts.tajawal(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: done ? Colors.white : context.brand.muted,
            ),
          ),
        );
      },
    );
  }
}
