import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';
import 'package:quran/modules/khatma/presentation/widgets/w_khatma_range_row.dart';

/// Card showing the current wird's from/to range on the tracker screen.
class WKhatmaCurrentWirdCard extends StatelessWidget {
  const WKhatmaCurrentWirdCard({super.key, required this.state});

  final SKhatma state;
  static const _border = Color(0xFFDDE6E0);

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
            style: AppTextStyles.grey14W400,
          ),
        ),
        Container(
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: WKhatmaRangeRow(
                  title: '${'khatma_from'.tr()} $startSurah',
                  subtitle: wird.startAyahText,
                  pageNumber: wird.startPageNumber,
                ),
              ),
              const Divider(height: 1, color: _border),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: WKhatmaRangeRow(
                  title: '${'khatma_to'.tr()} $endSurah: ${wird.endAyahNumber}',
                  subtitle: wird.endAyahText,
                  pageNumber: wird.endPageNumber,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
