import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';

class WSurahListTile extends StatelessWidget {
  const WSurahListTile({required this.surah, required this.onTap, super.key});

  final MSurah surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              _NumberBadge(number: surah.number),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.arabic,
                      style: GoogleFonts.amiri(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: context.brand.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${surah.name} · ${surah.translation}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: context.brand.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: (surah.isMakki
                              ? AppColorsLight.accent
                              : AppColorsLight.primary)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      surah.isMakki ? 'مكية' : 'مدنية',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: surah.isMakki
                            ? AppColorsLight.accent
                            : AppColorsLight.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '${surah.totalAyah} آية',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: context.brand.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.r,
      height: 44.r,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColorsLight.primary, AppColorsLight.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
