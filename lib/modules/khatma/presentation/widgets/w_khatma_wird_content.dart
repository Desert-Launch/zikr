import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/khatma/data/models/m_khatma_metadata.dart';

/// Inner content (day + surah range) shared by the suggested wird card and the
/// wird list rows on the wirds screen.
class WKhatmaWirdContent extends StatelessWidget {
  const WKhatmaWirdContent({super.key, required this.wird});

  final MKhatmaWird wird;

  @override
  Widget build(BuildContext context) {
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    final startSurah = isArabic ? wird.startSurahAr : wird.startSurahEn;
    final endSurah = isArabic ? wird.endSurahAr : wird.endSurahEn;
    return Row(
      children: [
        const Icon(Icons.chevron_left_rounded, size: 18),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${'khatma_wird_day'.tr()} ${wird.index}',
              style: TextStyle(fontSize: 15.sp),
            ),
            Text(
              '$startSurah ${wird.startAyahNumber} - '
              '$endSurah ${wird.endAyahNumber}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}
