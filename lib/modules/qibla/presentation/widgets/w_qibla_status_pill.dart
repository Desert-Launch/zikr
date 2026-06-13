import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WQiblaStatusPill extends StatelessWidget {
  const WQiblaStatusPill({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
    this.dotColor,
    this.showCheck = false,
    this.leadingEmoji,
  });

  final String text;
  final Color background;
  final Color foreground;
  final Color? dotColor;
  final bool showCheck;
  final String? leadingEmoji;

  @override
  Widget build(BuildContext context) {
    final emoji = leadingEmoji;
    final dot = dotColor;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (emoji != null) ...[
                Text(emoji, style: TextStyle(fontSize: 13.sp)),
                SizedBox(width: 6.w),
              ],
              Flexible(
                child: Text(
                  showCheck ? '$text ✓' : text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
          if (dot != null)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 8.r,
                height: 8.r,
                decoration: BoxDecoration(
                  color: dot,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
