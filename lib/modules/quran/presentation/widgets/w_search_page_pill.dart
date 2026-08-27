import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/presentation/widgets/mushaf_labels.dart';

/// The "صفحة ٤٩١" chip carried by every result that lands on a mushaf page.
///
/// The number is set in Arabic-Indic digits under the Arabic UI, matching the
/// running head printed on the page it points at.
class WSearchPagePill extends StatelessWidget {
  const WSearchPagePill({super.key, required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final label = 'search_page'
        .tr()
        .replaceFirst('{{page}}', isRtl ? arabicDigits(page) : '$page');

    return Container(
      decoration: BoxDecoration(
        color: brand.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, size: 12.r, color: brand.primary),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: brand.primary,
            ),
          ),
        ],
      ),
    );
  }
}
