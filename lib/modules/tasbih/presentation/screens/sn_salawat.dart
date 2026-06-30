import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/tasbih/presentation/cubits/cb_salawat.dart';
import 'package:quran/modules/tasbih/presentation/cubits/s_tasbih.dart';
import 'package:quran/modules/tasbih/presentation/widgets/w_salawat_reminder_sheet.dart';
import 'package:quran/modules/tasbih/presentation/widgets/w_tasbih_counter_card.dart';
import 'package:quran/modules/tasbih/presentation/widgets/w_tasbih_virtue_card.dart';

/// Single-zekr tasbih dedicated to salawat upon the Prophet ﷺ.
class SNSalawat extends StatelessWidget {
  const SNSalawat({super.key});

  static const _green = Color(0xFF007A58);
  static const _gold = Color(0xFFD6A72C);
  static const _canvas = Color(0xFFF8F7F4);

  @override
  Widget build(BuildContext context) {
    final cubit = Modular.get<CBSalawat>();
    return BlocProvider.value(
      value: cubit,
      child: WSharedScaffold(
        backgroundColor: _canvas,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: BlocBuilder<CBSalawat, STasbih>(
          builder: (_, state) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: WGradientAppBar(
                  title: 'home_salawat'.tr(),
                  subtitle: 'salawat_subtitle'.tr(),
                  actions: [
                    IconButton(
                      onPressed: () =>
                          WSalawatReminderSheet.show(context, cubit),
                      icon: Icon(
                        state.reminderEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 28.h),
                sliver: SliverList.list(
                  children: [
                    WTasbihCounterCard(
                      state: state,
                      totalToday: state.count,
                      green: _green,
                      onTap: cubit.tap,
                      onReset: cubit.reset,
                    ),
                    SizedBox(height: 12.h),
                    WTasbihVirtueCard(
                      gold: _gold,
                      titleKey: 'salawat_virtue_title',
                      bodyKey: 'salawat_virtue_body',
                      sourceKey: 'salawat_virtue_source',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
