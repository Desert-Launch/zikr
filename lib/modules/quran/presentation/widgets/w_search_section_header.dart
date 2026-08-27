import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/brand_colors.dart';

/// The heading above a group of search results — an accent rule, the group's
/// name, an optional count, then a hairline running to the far edge so the eye
/// reads the groups apart without a heavy divider between the cards.
class WSearchSectionHeader extends StatelessWidget {
  const WSearchSectionHeader({super.key, required this.title, this.count});

  final String title;

  /// Rendered after the title when set, already formatted for the locale.
  final String? count;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final count = this.count;
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 10.h),
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 16.h,
            decoration: BoxDecoration(
              color: brand.primary,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: brand.onSurface,
            ),
          ),
          if (count != null) ...[
            SizedBox(width: 6.w),
            Text(
              count,
              style: TextStyle(fontSize: 12.sp, color: brand.muted),
            ),
          ],
          SizedBox(width: 10.w),
          Expanded(child: Divider(height: 1.h, color: brand.border)),
        ],
      ),
    );
  }
}
