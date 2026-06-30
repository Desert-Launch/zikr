import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';

/// Printed-Mushaf style page chrome at the top of each page: the surah name on
/// the start side (right in RTL) and the juz' number on the end side (left).
///
/// Kept deliberately plain — no borders or medallions — so it reads as page
/// running-head, not a surah banner. Shared by the QPC and tajweed renderers.
class WMushafPageHeader extends StatelessWidget {
  const WMushafPageHeader({
    required this.surahName,
    required this.page,
    required this.color,
    super.key,
  });

  /// Arabic name of the surah at the top of the page.
  final String surahName;

  /// Page number (1–604) — used to derive the juz' label.
  final int page;

  /// Muted foreground that matches the page-number colour for the theme.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, right: 4.w, bottom: 6.h),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Start (right in RTL) → surah name.
            Flexible(
              child: Text(
                surahName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.amiri(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.1,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // End (left in RTL) → juz' number.
            Text(
              'الجزء ${CBMushafReader.juzForPage(page)}',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
