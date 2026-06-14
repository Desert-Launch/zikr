import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_outline_circle.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_stat_card.dart';

/// The tall green azkar header with a stats row (favorites / completed today /
/// categories). Shared by the home and category screens.
class WAzkarHeader extends StatelessWidget {
  const WAzkarHeader({
    super.key,
    required this.green,
    required this.categoryCount,
    required this.completedToday,
    required this.favorites,
    required this.onBack,
    this.title,
  });

  final Color green;
  final int categoryCount;
  final int completedToday;
  final int favorites;
  final VoidCallback onBack;

  /// Overrides the default header title. When null, falls back to the generic
  /// `azkar_header_title` translation.
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 228.h,
      padding: EdgeInsets.fromLTRB(0.w, 8.h, 0.w, 0.h),
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -44.w,
            top: -52.h,
            child: WAzkarOutlineCircle(size: 150.r),
          ),
          Positioned(
            left: -42.w,
            bottom: -64.h,
            child: WAzkarOutlineCircle(size: 150.r),
          ),
          Positioned(
            right: 105.w,
            top: 62.h,
            child: WAzkarOutlineCircle(size: 92.r),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 21.r,
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                        child: const Text('🤲', style: TextStyle(fontSize: 20)),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            title ?? 'azkar_header_title'.tr(),
                            style: GoogleFonts.cairo(color: Colors.white, fontSize: 21.sp, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'azkar_header_subtitle'.tr(),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 10.sp),
                          ),
                        ],
                      ),
                      SizedBox(width: 8.w),
                      IconButton(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 25.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: WAzkarStatCard(value: favorites, label: 'azkar_favorites'.tr()),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: WAzkarStatCard(value: completedToday, label: 'azkar_completed_today'.tr()),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: WAzkarStatCard(value: categoryCount, label: 'azkar_categories'.tr()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
