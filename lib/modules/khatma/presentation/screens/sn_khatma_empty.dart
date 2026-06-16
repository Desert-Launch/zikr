import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/modules/khatma/presentation/cubits/cb_khatma.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_description_card.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_start_card.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_virtue_card.dart';

class SNKhatmaEmpty extends StatelessWidget {
  const SNKhatmaEmpty({super.key});

  static const _canvas = Color(0xFFF8F7F4);

  // Surah Fatir (35:29) — Quranic text is not localized.
  static const _verse =
      'إِنَّ الَّذِينَ يَتْلُونَ كِتَابَ اللَّهِ وَأَقَامُوا الصَّلَاةَ '
      'وَأَنْفَقُوا مِمَّا رَزَقْنَاهُمْ سِرًّا وَعَلَانِيَةً يَرْجُونَ '
      'تِجَارَةً لَنْ تَبُورَ';

  @override
  Widget build(BuildContext context) {
    final cubit = Modular.get<CBKhatma>();
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<CBKhatma, SKhatma>(
        builder: (_, state) {
          if (state.isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (state.hasActivePlan) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Modular.to.path == KhatmaRoutes.fullHome()) {
                Modular.to.pushReplacementNamed(KhatmaRoutes.fullTracker());
              }
            });
            return const Scaffold(body: SizedBox.shrink());
          }
          return Scaffold(
            backgroundColor: _canvas,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WGradientAppBar(title: 'khatma_daily_wird'.tr()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 28.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WKhatmaDescriptionCard(text: 'khatma_empty_desc'.tr()),
                        SizedBox(height: 16.h),
                        WKhatmaStartCard(
                          title: 'khatma_start_new'.tr(),
                          onTap: () => Modular.to.pushNamed(KhatmaRoutes.fullPlans()),
                        ),
                        SizedBox(height: 16.h),
                        WKhatmaVirtueCard(title: 'khatma_virtue_title'.tr(), verse: _verse, reference: '[فاطر: 29]'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
