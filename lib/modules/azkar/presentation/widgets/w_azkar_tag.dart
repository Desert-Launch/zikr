import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A small pill label (filled or outlined) used for a zekr's source / virtue.
class WAzkarTag extends StatelessWidget {
  const WAzkarTag({super.key, required this.text, required this.color, this.outlined = false});

  final String text;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 150.w),
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: outlined ? Colors.white : color,
        borderRadius: BorderRadius.circular(12.r),
        border: outlined ? Border.all(color: color.withValues(alpha: 0.25)) : null,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: outlined ? color : Colors.black87, fontSize: 8.sp),
      ),
    );
  }
}
