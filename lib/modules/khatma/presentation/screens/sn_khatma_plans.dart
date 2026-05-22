import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/khatma/presentation/cubits/cb_khatma.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';

class SNKhatmaPlans extends StatelessWidget {
  const SNKhatmaPlans({super.key});

  static const _presets = [
    (30, 'khatma_plan_30'),
    (60, 'khatma_plan_60'),
    (90, 'khatma_plan_90'),
  ];

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
              icon: const Icon(Icons.history_rounded),
              tooltip: 'khatma_history'.tr(),
              onPressed: () => Modular.to.pushNamed(KhatmaRoutes.fullHistory()),
            ),
          ],
        ),
        body: BlocBuilder<CBKhatma, SKhatma>(
          builder: (context, state) {
            if (state.hasActivePlan) {
              // Active plan → route to tracker on first frame.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Modular.to.path == KhatmaRoutes.fullPlans()) {
                  Modular.to.pushReplacementNamed(KhatmaRoutes.fullTracker());
                }
              });
              return const SizedBox.shrink();
            }
            return ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: Text('khatma_pick_plan'.tr(),
                      style: TextStyle(
                        fontSize: 14.sp, color: context.brand.muted,
                      )),
                ),
                ..._presets.map((preset) => _PlanCard(
                      days: preset.$1,
                      titleKey: preset.$2,
                      onTap: () async {
                        await cb.startPlan(preset.$1);
                        if (!context.mounted) return;
                        Modular.to.pushReplacementNamed(
                            KhatmaRoutes.fullTracker());
                      },
                    )),
                SizedBox(height: 12.h),
                _CustomDaysCard(onSubmit: (n) async {
                  await cb.startPlan(n);
                  if (!context.mounted) return;
                  Modular.to.pushReplacementNamed(KhatmaRoutes.fullTracker());
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.days,
    required this.titleKey,
    required this.onTap,
  });
  final int days;
  final String titleKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pagesPerDay = (604 / days).ceil();
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: context.brand.surface,
            border: Border.all(color: context.brand.border),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            children: [
              Container(
                width: 50.r,
                height: 50.r,
                decoration: BoxDecoration(
                  color: AppColorsLight.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text('$days',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColorsLight.primary,
                      )),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titleKey.tr(),
                        style: TextStyle(
                          fontSize: 15.sp, fontWeight: FontWeight.w800,
                        )),
                    SizedBox(height: 2.h),
                    Text(
                      'khatma_pages_per_day'
                          .tr()
                          .replaceFirst('{{n}}', '$pagesPerDay'),
                      style: TextStyle(
                        fontSize: 12.sp, color: context.brand.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomDaysCard extends StatefulWidget {
  const _CustomDaysCard({required this.onSubmit});
  final ValueChanged<int> onSubmit;

  @override
  State<_CustomDaysCard> createState() => _CustomDaysCardState();
}

class _CustomDaysCardState extends State<_CustomDaysCard> {
  int _days = 45;

  @override
  Widget build(BuildContext context) {
    final ppd = (604 / _days).ceil();
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
          Text('khatma_custom'.tr(),
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800)),
          SizedBox(height: 4.h),
          Text(
            'khatma_pages_per_day'.tr().replaceFirst('{{n}}', '$ppd'),
            style: TextStyle(fontSize: 12.sp, color: context.brand.muted),
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _days.toDouble(),
                  min: 7,
                  max: 365,
                  divisions: 358,
                  label: '$_days',
                  onChanged: (v) => setState(() => _days = v.round()),
                ),
              ),
              SizedBox(
                width: 48.r,
                child: Text('$_days',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    )),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => widget.onSubmit(_days),
              style: FilledButton.styleFrom(
                backgroundColor: AppColorsLight.primary,
              ),
              child: Text('khatma_start_custom'.tr(),
                  style: TextStyle(
                    fontSize: 14.sp, fontWeight: FontWeight.w700,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
