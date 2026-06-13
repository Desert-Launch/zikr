import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/khatma/presentation/cubits/s_khatma.dart';

/// Active-plan summary card (completed/total + plan name) on the tracker screen.
class WKhatmaPlanSummaryCard extends StatelessWidget {
  const WKhatmaPlanSummaryCard({super.key, required this.state});

  final SKhatma state;

  @override
  Widget build(BuildContext context) {
    final metadata = state.metadata;
    if (metadata == null) return const SizedBox.shrink();
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFDDE6E0)),
      ),
      child: Row(
        children: [
          Text(
            '${state.completedDays} / ${state.wirds.length}',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            isArabic ? metadata.nameAr : metadata.nameEn,
            style: TextStyle(fontSize: 15.sp),
          ),
        ],
      ),
    );
  }
}
