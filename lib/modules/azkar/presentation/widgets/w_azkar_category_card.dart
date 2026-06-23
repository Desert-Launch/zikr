import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';

/// A colored category tile in the azkar home grid. Shows an emoji, the category
/// title and an item count (or a "browse" hint when [count] is negative).
class WAzkarCategoryCard extends StatelessWidget {
  const WAzkarCategoryCard({
    super.key,
    required this.title,
    required this.count,
    required this.color,
    required this.emoji,
    required this.onTap,
  });

  final String title;
  final int count;
  final Color color;
  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 9, offset: const Offset(0, 5))],
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -37.h,
              end: -37.w,
              child: Container(
                width: 70.r,
                height: 70.r,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(15),
              child: Align(
                alignment: Alignment.topRight,
                child: Text(emoji, style: AppTextStyles.white24W400.copyWith(fontSize: 30.sp)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  children: [
                    Icon(Icons.chevron_left_rounded, color: Colors.white.withValues(alpha: 0.72), size: 18.r),
                    const Spacer(),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.white16W500),
                        SizedBox(height: 2.h),
                        Text(
                          count >= 0 ? '$count ${'azkar_items_suffix'.tr()}' : 'azkar_browse'.tr(),
                          style: AppTextStyles.white12W400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
