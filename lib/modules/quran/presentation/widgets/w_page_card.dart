import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/quran/domain/entities/e_page_entry.dart';
import 'package:quran/modules/quran/presentation/widgets/w_star_number.dart';

class WPageCard extends StatelessWidget {
  const WPageCard({super.key, required this.entry, required this.green, required this.onTap});

  final EPageEntry entry;
  final Color green;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Row(
          children: [
            WStarNumber(number: entry.page, green: green),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    entry.surahArabic,
                    style: GoogleFonts.amiri(fontSize: 18.sp, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'search_page'.tr().replaceFirst('{{page}}', '${entry.page}'),
                    textAlign: TextAlign.end,
                    style: AppTextStyles.grey12W400,
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
