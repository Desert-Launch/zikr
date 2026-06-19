import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/khatma/presentation/cubits/cb_khatma.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_current_wird_card.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_plan_summary_card.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_progress_card.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_reminder_card.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_section_label.dart';

class SNKhatmaTracker extends StatelessWidget {
  const SNKhatmaTracker({super.key});

  static const _green = Color(0xFF347B60);
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
          return WSharedScaffold(
            backgroundColor: _canvas,
            withSafeArea: false,
            padding: EdgeInsets.zero,
            body: ListView(
              padding: EdgeInsets.zero,
              children: [
                WGradientAppBar(title: 'khatma_wird_title'.tr()),
                Padding(
                  padding: EdgeInsets.fromLTRB(28.w, 30.h, 28.w, 28.h),
                  child: Column(
                    children: [
                      WKhatmaCurrentWirdCard(state: state),
                      SizedBox(height: 30.h),
                      SizedBox(
                        width: double.infinity,
                        height: 75.h,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: Colors.black.withValues(alpha: 0.22),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28.r),
                            ),
                          ),
                          onPressed: () => _complete(context, cubit, state),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 28,
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  'khatma_complete_wird'.tr(),
                                  style: AppTextStyles.white20W700,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 28.h),
                      WKhatmaSectionLabel(
                        'khatma_reminder'.tr(),
                        aligned: true,
                      ),
                      WKhatmaReminderCard(cubit: cubit, state: state),
                      SizedBox(height: 28.h),
                      WKhatmaSectionLabel(
                        'khatma_current_plan'.tr(),
                        aligned: true,
                      ),
                      WKhatmaProgressCard(state: state),
                      SizedBox(height: 28.h),
                      WKhatmaSectionLabel(
                        'khatma_current_plan'.tr(),
                        aligned: true,
                      ),
                      WKhatmaPlanSummaryCard(state: state),
                      SizedBox(height: 18.h),
                      SizedBox(
                        width: double.infinity,
                        height: 96.h,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF3B3B),
                            side: const BorderSide(color: _border),
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                          ),
                          onPressed: () => _cancel(context, cubit),
                          child: Text(
                            'khatma_cancel_plan'.tr(),
                            style: AppTextStyles.ink16W700.copyWith(
                              color: const Color(0xFFFF3B3B),
                            ),
                          ),
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
          title: Text(
            'khatma_second_today_warning_title'.tr(),
            style: AppTextStyles.ink18W700,
          ),
          content: Text(
            'khatma_second_today_warning_body'.tr(),
            style: AppTextStyles.grey14W400,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'common_cancel'.tr(),
                style: AppTextStyles.grey14W500,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'khatma_continue_completion'.tr(),
                style: AppTextStyles.white14W700,
              ),
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
        title: Text(
          'khatma_cancel_confirm'.tr(),
          style: AppTextStyles.ink18W700,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('common_cancel'.tr(), style: AppTextStyles.grey14W500),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'common_delete'.tr(),
              style: AppTextStyles.ink14W700.copyWith(
                color: const Color(0xFFFF3B3B),
              ),
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
