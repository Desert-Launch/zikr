import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/khatma/presentation/cubits/cb_khatma.dart';

class SNKhatmaHistory extends StatelessWidget {
  const SNKhatmaHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = Modular.get<CBKhatma>().history();
    return Scaffold(
      appBar: AppBar(
        title: Text('khatma_history'.tr(),
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700)),
      ),
      body: entries.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text('khatma_history_empty'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp, color: context.brand.muted,
                    )),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              itemCount: entries.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (_, i) {
                final c = entries[i];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: context.brand.border),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(14.w),
                    child: Row(
                      children: [
                        Container(
                          width: 44.r,
                          height: 44.r,
                          decoration: BoxDecoration(
                            color: AppColorsLight.accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.auto_awesome_rounded,
                              color: AppColorsLight.accent, size: 22.r),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'khatma_history_entry'
                                    .tr()
                                    .replaceFirst('{{n}}',
                                        '${c.planTotalDays}'),
                                style: TextStyle(
                                  fontSize: 14.sp, fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '${_fmt(c.startedAt)} → ${_fmt(c.completedAt)}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: context.brand.muted,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColorsLight.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            '${c.longestStreakDays}🔥',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColorsLight.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  static String _fmt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
  }
}
