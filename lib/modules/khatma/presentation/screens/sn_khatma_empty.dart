import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/modules/khatma/presentation/cubits/cb_khatma.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';

class SNKhatmaEmpty extends StatelessWidget {
  const SNKhatmaEmpty({super.key});

  static const _gold = Color(0xFFD6A72C);
  static const _canvas = Color(0xFFF8F7F4);

  // Surah Fatir (35:29) — Quranic text is not localized.
  static const _verse =
      '﴿ إِنَّ الَّذِينَ يَتْلُونَ كِتَابَ اللَّهِ وَأَقَامُوا الصَّلَاةَ '
      'وَأَنْفَقُوا مِمَّا رَزَقْنَاهُمْ سِرًّا وَعَلَانِيَةً يَرْجُونَ '
      'تِجَارَةً لَنْ تَبُورَ ﴾';

  @override
  Widget build(BuildContext context) {
    final cubit = Modular.get<CBKhatma>();
    return BlocProvider.value(
      value: cubit,
      child: BlocBuilder<CBKhatma, SKhatma>(
        builder: (_, state) {
          if (state.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
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
                        _DescriptionCard(text: 'khatma_empty_desc'.tr()),
                        SizedBox(height: 16.h),
                        _StartCard(
                          title: 'khatma_start_new'.tr(),
                          onTap: () =>
                              Modular.to.pushNamed(KhatmaRoutes.fullPlans()),
                        ),
                        SizedBox(height: 16.h),
                        _VirtueCard(
                          title: 'khatma_virtue_title'.tr(),
                          verse: _verse,
                          reference: '[فاطر: 29]',
                        ),
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

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 22.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE0E7E2)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15.sp,
          height: 1.7,
          color: const Color(0xFF3A463F),
        ),
      ),
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE0E7E2)),
        ),
        child: Row(
          children: [
            Container(
              width: 52.r,
              height: 52.r,
              decoration: const BoxDecoration(
                color: SNKhatmaEmpty._gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              title,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF1F2A24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VirtueCard extends StatelessWidget {
  const _VirtueCard({
    required this.title,
    required this.verse,
    required this.reference,
  });

  final String title;
  final String verse;
  final String reference;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 18.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EBCB),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: SNKhatmaEmpty._gold.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: const BoxDecoration(
              color: SNKhatmaEmpty._gold,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star_rounded, color: Colors.white, size: 26.r),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFF9A7B2E),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: 60.w,
            height: 1,
            color: SNKhatmaEmpty._gold.withValues(alpha: 0.4),
          ),
          SizedBox(height: 12.h),
          Text(
            verse,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              height: 1.9,
              color: const Color(0xFF4A3D1E),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            reference,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF9A7B2E),
            ),
          ),
        ],
      ),
    );
  }
}
