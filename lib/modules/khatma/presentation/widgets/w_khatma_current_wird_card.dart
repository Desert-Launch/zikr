import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_range_row.dart';

/// Card showing the current wird's from/to range on the tracker screen.
class WKhatmaCurrentWirdCard extends StatelessWidget {
  const WKhatmaCurrentWirdCard({super.key, required this.state});

  final SKhatma state;

  @override
  Widget build(BuildContext context) {
    final wird = state.currentWird;
    if (wird == null) return const SizedBox.shrink();
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    final startSurah = isArabic ? wird.startSurahAr : wird.startSurahEn;
    final endSurah = isArabic ? wird.endSurahAr : wird.endSurahEn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(end: 5.w, bottom: 6.h),
          child: Text(
            '${'khatma_wird_day'.tr()} ${wird.index}',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: const Color(0xFFDDE6E0)),
          ),
          child: Column(
            children: [
              WKhatmaRangeRow(
                title: '${'khatma_from'.tr()} $startSurah',
                subtitle: '${'khatma_ayah'.tr()} ${wird.startAyahNumber}',
                pageNumber: wird.startPageNumber,
              ),
              const Divider(height: 1),
              WKhatmaRangeRow(
                title: '${'khatma_to'.tr()} $endSurah',
                subtitle: '${'khatma_ayah'.tr()} ${wird.endAyahNumber}',
                pageNumber: wird.endPageNumber,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
