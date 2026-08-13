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
  const WMushafPageFooter({
    required this.page,
    required this.color,
    this.sajdahColor,
    super.key,
  });

  /// Page number (1–604) — also derives the sajdah marker.
  final int page;

  /// Muted foreground that matches the header colour for the theme.
  final Color color;

  /// Colour for the sajdah mark. It deliberately breaks away from [color]:
  /// the muted running-foot grey made the sign easy to miss, and a sajdah is
  /// the one thing on this line the reader must notice. Falls back to [color].
  final Color? sajdahColor;

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet;
    final hasSajdah = SajdahMarks.onPage(page);
    final sajdahTint = sajdahColor ?? color;

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
                  ? Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 8.w : 5.w,
                          vertical: isTablet ? 3.h : 1.h,
                        ),
                        decoration: BoxDecoration(
                          color: sajdahTint.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          '${SajdahMarks.sign} سجدة',
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          // Amiri carries the sajdah sign; the platform default
                          // renders it as a box on some Android builds.
                          style: GoogleFonts.amiri(
                            fontSize: isTablet ? 20.sp : 12.sp,
                            fontWeight: FontWeight.w700,
                            color: sajdahTint,
                            height: 1.1,
                          ),
                        ),
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
