import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/modules/khatma/data/datasources/local/ds_local_khatma.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';
import 'package:quran/modules/khatma/presentation/cubits/cb_khatma.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';

class SNKhatmaPlans extends StatelessWidget {
  const SNKhatmaPlans({super.key});

  static const _canvas = Color(0xFFF8F7F4);

  @override
  Widget build(BuildContext context) {
    final cubit = Modular.get<CBKhatma>();
    final local = Modular.get<DSLocalKhatma>();
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<CBKhatma, SKhatma>(
        builder: (_, state) {
          if (state.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return Scaffold(
            backgroundColor: _canvas,
            body: FutureBuilder<List<MKhatmaMetadata>>(
              future: local.metadata(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final plans = snapshot.data!;
                final suggested = plans.where((plan) => plan.isSuggested);
                final others = plans.where((plan) => !plan.isSuggested);
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: WGradientAppBar(title: 'khatma_new_title'.tr()),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
                      sliver: SliverList.list(
                        children: [
                          if (suggested.isNotEmpty) ...[
                            _SectionLabel('khatma_suggested'.tr()),
                            ...suggested.map(
                              (plan) => _PlanCard(
                                plan: plan,
                                suggested: true,
                                onTap: () => Modular.to.pushNamed(
                                  KhatmaRoutes.fullWirds(plan.id),
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                          ],
                          _SectionLabel('khatma_all_plans'.tr()),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: const Color(0xFFE0E7E2),
                              ),
                            ),
                            child: Column(
                              children: [
                                for (final plan in others) ...[
                                  _PlanRow(
                                    plan: plan,
                                    onTap: () => Modular.to.pushNamed(
                                      KhatmaRoutes.fullWirds(plan.id),
                                    ),
                                  ),
                                  if (plan != others.last)
                                    const Divider(
                                      height: 1,
                                      indent: 12,
                                      endIndent: 12,
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 5.w, bottom: 6.h),
      child: Text(
        text,
        textAlign: TextAlign.end,
        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.suggested,
    required this.onTap,
  });

  final MKhatmaMetadata plan;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xFFDDE6E0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.chevron_left_rounded),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isArabic ? plan.nameAr : plan.nameEn,
                  style: TextStyle(fontSize: 16.sp),
                ),
                Text(
                  isArabic ? plan.quartersPerDayAr : plan.quartersPerDayEn,
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

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.plan, required this.onTap});

  final MKhatmaMetadata plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    return ListTile(
      dense: true,
      leading: const Icon(Icons.chevron_left_rounded, size: 18),
      title: Text(
        isArabic ? plan.nameAr : plan.nameEn,
        textAlign: TextAlign.end,
        style: TextStyle(fontSize: 15.sp),
      ),
      subtitle: Text(
        isArabic ? plan.quartersPerDayAr : plan.quartersPerDayEn,
        textAlign: TextAlign.end,
        style: TextStyle(fontSize: 12.sp),
      ),
      onTap: onTap,
    );
  }
}
