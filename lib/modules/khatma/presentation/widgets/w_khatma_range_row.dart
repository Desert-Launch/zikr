import 'package:flutter/material.dart';
import 'package:quran/core/widgets/w_localize_rotation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/services/routes/routes_names.dart';

/// A tappable "from/to" range row opening the mushaf at the given ayah
/// (highlighted), falling back to [pageNumber] when the surah is unresolved.
class WKhatmaRangeRow extends StatelessWidget {
  const WKhatmaRangeRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pageNumber,
    this.surahNumber = 0,
    this.ayahNumber = 0,
  });

  final String title;
  final String subtitle;
  final int pageNumber;
  final int surahNumber;
  final int ayahNumber;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Modular.to.pushNamed(
        surahNumber > 0 && ayahNumber > 0
            ? QuranRoutes.readerFromAyah(surahNumber, ayahNumber)
            : QuranRoutes.readerFromPage(pageNumber),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.ink16W400,
                  ),
                  SizedBox(height: 2.h),
                  // Ayah text is Arabic regardless of the UI language.
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.grey12W400,
                  ),
                ],
              ),
            ),
            SizedBox(width: 20.w),
            WLocalizeRotation(
              reverse: true,
              child: Icon(
                Icons.chevron_left_rounded,
                size: 30.r,
                color: const Color(0xFF6B6B6B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
