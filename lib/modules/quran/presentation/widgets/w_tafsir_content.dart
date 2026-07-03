import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_entry.dart';

/// Renders one book's HTML commentary for an ayah, scrollable, with correct
/// text direction for the book's language.
class WTafsirContent extends StatelessWidget {
  const WTafsirContent({required this.entry, super.key});

  final ETafsirEntry entry;

  @override
  Widget build(BuildContext context) {
    final dir = entry.book.isRtl ? TextDirection.rtl : TextDirection.ltr;
    final onSurface = context.brand.onSurface;

    return Directionality(
      textDirection: dir,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BookHeader(entry: entry),
            SizedBox(height: 12.h),
            Html(
              data: entry.html,
              style: {
                'body': Style(
                  margin: Margins.zero,
                  fontSize: FontSize(16.sp),
                  lineHeight: LineHeight(1.7),
                  color: onSurface,
                  fontFamily: entry.book.isRtl
                      ? GoogleFonts.notoNaskhArabic().fontFamily
                      : null,
                  direction: dir,
                ),
                'h1': Style(fontSize: FontSize(19.sp), fontWeight: FontWeight.w700),
                'h2': Style(fontSize: FontSize(18.sp), fontWeight: FontWeight.w700),
                'h3': Style(fontSize: FontSize(17.sp), fontWeight: FontWeight.w600),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BookHeader extends StatelessWidget {
  const _BookHeader({required this.entry});
  final ETafsirEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_stories_rounded, size: 16.r, color: context.brand.primary),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                entry.book.name,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: context.brand.primary,
                ),
              ),
            ),
          ],
        ),
        if (entry.isLinked) ...[
          SizedBox(height: 6.h),
          Text(
            'tafsir_linked_note'.tr().replaceFirst('{{ayah}}', entry.linkedFromKey ?? ''),
            style: AppTextStyles.grey12W400,
          ),
        ],
        SizedBox(height: 10.h),
        Divider(height: 1, color: context.brand.surfaceMuted),
      ],
    );
  }
}
