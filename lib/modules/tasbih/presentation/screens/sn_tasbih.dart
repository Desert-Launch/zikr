import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/tasbih/presentation/cubits/cb_tasbih.dart';
import 'package:quran/modules/tasbih/presentation/cubits/s_tasbih.dart';
import 'package:quran/modules/tasbih/presentation/widgets/w_tasbih_counter_card.dart';
import 'package:quran/modules/tasbih/presentation/widgets/w_tasbih_phrase_selector.dart';
import 'package:quran/modules/tasbih/presentation/widgets/w_tasbih_target_selector.dart';
import 'package:quran/modules/tasbih/presentation/widgets/w_tasbih_virtue_card.dart';

class SNTasbih extends StatelessWidget {
  const SNTasbih({super.key});

  static const _green = Color(0xFF007A58);
  static const _gold = Color(0xFFD6A72C);
  static const _canvas = Color(0xFFF8F7F4);

  static const _phrases = [
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'لَا إِلَهَ إِلَّا اللَّهُ',
    'اللَّهُ أَكْبَرُ',
    'أَسْتَغْفِرُ اللَّهَ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
  ];

  @override
  Widget build(BuildContext context) {
    final cubit = Modular.get<CBTasbih>();
    return BlocProvider.value(
      value: cubit,
      child: WSharedScaffold(
        backgroundColor: _canvas,
        withSafeArea: false,
        padding: EdgeInsets.zero,
        body: BlocBuilder<CBTasbih, STasbih>(
          builder: (_, state) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: WGradientAppBar(
                  title: 'tasbih_digital_title'.tr(),
                  subtitle: 'tasbih_digital_subtitle'.tr(),
                  actions: [
                    IconButton(
                      onPressed: () => Modular.to.pushNamed(TasbihRoutes.fullHourly()),
                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 28.h),
                sliver: SliverList.list(
                  children: [
                    WTasbihPhraseSelector(
                      selected: state.zekrAr,
                      phrases: _phrases,
                      green: _green,
                      onChanged: cubit.setZekr,
                    ),
                    SizedBox(height: 12.h),
                    WTasbihTargetSelector(
                      target: state.target,
                      green: _green,
                      onChanged: cubit.setTarget,
                    ),
                    SizedBox(height: 12.h),
                    WTasbihCounterCard(
                      state: state,
                      totalToday: state.count,
                      green: _green,
                      onTap: cubit.tap,
                      onReset: cubit.reset,
                    ),
                    SizedBox(height: 12.h),
                    WTasbihVirtueCard(gold: _gold),
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
