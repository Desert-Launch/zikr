import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/modules/khatma/presentation/cubits/cb_khatma.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_current_wird_card.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_plan_summary_card.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_progress_card.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_reminder_card.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_section_label.dart';

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
                      WKhatmaCurrentWirdCard(state: state),
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
                      WKhatmaSectionLabel(
                        'khatma_reminder'.tr(),
                        aligned: true,
                      ),
                      WKhatmaReminderCard(cubit: cubit, state: state),
                      SizedBox(height: 16.h),
                      WKhatmaSectionLabel(
                        'khatma_current_plan'.tr(),
                        aligned: true,
                      ),
                      WKhatmaProgressCard(state: state),
                      SizedBox(height: 12.h),
                      WKhatmaPlanSummaryCard(state: state),
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
