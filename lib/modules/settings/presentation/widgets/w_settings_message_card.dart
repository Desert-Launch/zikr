import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/theme/app_colors.dart';

/// A white card of copy on a settings page: an optional [heading], then
/// [paragraphs], with [quote] (a hadith) set apart in a tinted block after the
/// heading. [footer] sits under the text — the share or rate button.
class WSettingsMessageCard extends StatelessWidget {
  const WSettingsMessageCard({
    required this.paragraphs,
    this.heading,
    this.quote,
    this.footer,
    super.key,
  });

  final String? heading;
  final String? quote;
  final List<String> paragraphs;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final heading = this.heading;
    final quote = this.quote;
    final footer = this.footer;
    final gap = SizedBox(height: 12.h);
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 22.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19.r),
        border: Border.all(color: const Color(0xFFE2ECE8)),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 3, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (heading != null) ...[
            Text(
              heading,
              style: GoogleFonts.cairo(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppColorsLight.primaryDark,
                height: 1.5,
              ),
            ),
            gap,
          ],
          if (quote != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColorsLight.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(
                quote,
                style: GoogleFonts.cairo(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColorsLight.primary,
                  height: 1.8,
                ),
              ),
            ),
            gap,
          ],
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) gap,
            Text(
              paragraphs[i],
              style: GoogleFonts.cairo(fontSize: 14.sp, color: const Color(0xFF303030), height: 1.8),
            ),
          ],
          if (footer != null) ...[
            SizedBox(height: 20.h),
            footer,
          ],
        ],
      ),
    );
  }
}
