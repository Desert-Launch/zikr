import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/presentation/widgets/w_star_number.dart';

class WSurahCard extends StatelessWidget {
  const WSurahCard({
    super.key,
    required this.surah,
    required this.green,
    required this.gold,
    required this.onTap,
  });

  final MSurah surah;
  final Color green;
  final Color gold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = surah.isMakki ? green : gold;
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0B000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            WStarNumber(number: surah.number, green: green),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          surah.isMakki
                              ? 'surah_list_meccan'.tr()
                              : 'surah_list_medinan'.tr(),
                          style: TextStyle(color: typeColor, fontSize: 8.sp),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        surah.arabic,
                        style: GoogleFonts.amiri(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${surah.name} · ${surah.totalAyah} '
                    '${'quran_ayah_label'.tr()}',
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 8.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
