import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A value/label stat tile used in the azkar headers. [compact] switches to the
/// smaller sizing used by the player's header.
class WAzkarStatCard extends StatelessWidget {
  const WAzkarStatCard({
    super.key,
    required this.value,
    required this.label,
    this.compact = false,
  });

  final int value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 7.h : 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(compact ? 12.r : 14.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 14.sp : 18.sp,
              fontWeight: compact ? FontWeight.w400 : FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: compact ? 0.7 : 0.76),
              fontSize: compact ? 7.sp : 9.sp,
            ),
          ),
        ],
      ),
    );
  }
}
