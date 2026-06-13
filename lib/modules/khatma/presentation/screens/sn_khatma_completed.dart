import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/khatma/presentation/cubits/cb_khatma.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_stat_row.dart';
import 'package:share_plus/share_plus.dart';

class SNKhatmaCompleted extends StatelessWidget {
  const SNKhatmaCompleted({super.key});

  @override
  Widget build(BuildContext context) {
    final cb = Modular.get<CBKhatma>();
    final history = cb.history();
    final latest = history.isNotEmpty ? history.first : null;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(24.w),
          children: [
            SizedBox(height: 16.h),
            Container(
              width: 160.r,
              height: 160.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColorsLight.accent, Color(0xFFE0BD4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 80.r),
            ),
            SizedBox(height: 24.h),
            Text('khatma_done_headline'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColorsLight.primaryDark,
                )),
            SizedBox(height: 8.h),
            Text('khatma_done_blessing'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp, color: context.brand.muted,
                )),
            SizedBox(height: 28.h),
            if (latest != null)
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: context.brand.surface,
                  border: Border.all(color: context.brand.border),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    WKhatmaStatRow(
                      label: 'khatma_total_days'.tr(),
                      value: '${latest.daysCompleted}',
                    ),
                    Divider(height: 16.h),
                    WKhatmaStatRow(
                      label: 'khatma_longest_streak'.tr(),
                      value: '${latest.longestStreakDays}',
                    ),
                    Divider(height: 16.h),
                    WKhatmaStatRow(
                      label: 'khatma_plan_length'.tr(),
                      value: '${latest.planTotalDays}',
                    ),
                  ],
                ),
              ),
            SizedBox(height: 24.h),
            FilledButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: Text('khatma_start_new'.tr(),
                  style: TextStyle(
                    fontSize: 15.sp, fontWeight: FontWeight.w700,
                  )),
              onPressed: () =>
                  Modular.to.pushReplacementNamed(KhatmaRoutes.fullPlans()),
              style: FilledButton.styleFrom(
                backgroundColor: AppColorsLight.primary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            OutlinedButton.icon(
              icon: const Icon(Icons.share_outlined),
              label: Text('khatma_share'.tr()),
              onPressed: () => Share.share('khatma_share_text'.tr()),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
            SizedBox(height: 4.h),
            TextButton(
              onPressed: () =>
                  Modular.to.pushNamed(KhatmaRoutes.fullHistory()),
              child: Text('khatma_view_history'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
