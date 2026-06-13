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
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_plan_card.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_plan_row.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_section_label.dart';

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
                            WKhatmaSectionLabel(
                              'khatma_suggested'.tr(),
                              padding: EdgeInsetsDirectional.only(
                                start: 5.w,
                                bottom: 6.h,
                              ),
                            ),
                            ...suggested.map(
                              (plan) => WKhatmaPlanCard(
                                plan: plan,
                                suggested: true,
                                onTap: () => Modular.to.pushNamed(
                                  KhatmaRoutes.fullWirds(plan.id),
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                          ],
                          WKhatmaSectionLabel(
                            'khatma_all_plans'.tr(),
                            padding: EdgeInsetsDirectional.only(
                              start: 5.w,
                              bottom: 6.h,
                            ),
                          ),
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
                                  WKhatmaPlanRow(
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
