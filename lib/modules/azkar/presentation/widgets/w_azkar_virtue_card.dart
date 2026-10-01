import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show Bidi;
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';

/// The gold card under a zekr in the player: star badge, "فضل" label, the
/// virtue itself, and — when the data carries one — the narrator line.
class WAzkarVirtueCard extends StatelessWidget {
  const WAzkarVirtueCard({super.key, required this.text, required this.gold});

  /// Newline-separated virtue lines — the Arabic `fadel_zeker`, or the
  /// English `reference`, which reads left-to-right.
  final String text;
  final Color gold;

  /// Lines that credit the hadith collection rather than describe the virtue.
  static const _narratorPrefixes = ['رواه', 'أخرجه', 'متفق'];

  static bool _isNarrator(String line) => _narratorPrefixes.any(line.startsWith);

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final body = lines.where((l) => !_isNarrator(l)).join('\n');
    final source = lines.where(_isNarrator).join(' · ');
    final rtl = Bidi.detectRtlDirectionality(body);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7DF), Color(0xFFFBEBBE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: gold),
        boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.22), blurRadius: 22, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -35.h,
              right: -30.w,
              child: Container(
                width: 100.r,
                height: 100.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: gold.withValues(alpha: 0.15), width: 3),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18.r,
                    backgroundColor: gold,
                    child: Icon(Icons.star_rounded, color: Colors.white, size: 20.sp),
                  ),
                  SizedBox(height: 6.h),
                  Text('azkar_virtue'.tr(), style: AppTextStyles.grey12W400),
                  if (body.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Directionality(
                      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                      child: Text(
                        body,
                        textAlign: TextAlign.center,
                        style: rtl
                            ? GoogleFonts.amiri(fontSize: 15.sp, height: 1.9, color: const Color(0xFF1A1A1A))
                            : AppTextStyles.ink14W400.copyWith(fontSize: 13.sp, height: 1.6),
                      ),
                    ),
                  ],
                  if (source.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(source, textAlign: TextAlign.center, style: AppTextStyles.grey12W400),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
