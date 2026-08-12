import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/modules/quran/domain/entities/sajdah_marks.dart';

/// Printed-Mushaf style page chrome at the foot of each page: the page number
/// in the middle and — only on the fifteen pages that carry one — the sajdah
/// sign on the end side (left in RTL).
///
/// The hizb/rub' label used to sit on the start side; it now rides in the
/// reader's top bar under the juz', where it stays legible without stealing a
/// line of page height.
///
/// Deliberately plain, like [WMushafPageHeader]: it reads as a running foot,
/// not a badge. The page number stays optically centred because the two side
/// slots are equal-width [Expanded]s, so a page with no sajdah does not shift
/// its number.
class WMushafPageFooter extends StatelessWidget {
  const WMushafPageFooter({required this.page, required this.color, super.key});

  /// Page number (1–604) — also derives the sajdah marker.
  final int page;

  /// Muted foreground that matches the header colour for the theme.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final hasSajdah = SajdahMarks.onPage(page);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Row(
          children: [
            // Empty twin of the sajdah slot, so the number sits dead centre.
            const Expanded(child: SizedBox.shrink()),
            Text(
              '$page',
              style: TextStyle(fontSize: isTablet ? 18.sp : 11.sp, color: color),
            ),
            // End (left in RTL) → sajdah, on the pages that print one.
            Expanded(
              child: hasSajdah
                  ? Text(
                      '${SajdahMarks.sign} سجدة',
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      // Amiri carries the sajdah sign; the platform default
                      // renders it as a box on some Android builds.
                      style: GoogleFonts.amiri(
                        fontSize: isTablet ? 20.sp : 12.sp,
                        fontWeight: FontWeight.w700,
                        color: color,
                        height: 1.1,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
