import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Single prayer chip: tinted circle glyph, label, and time.
class WHomePrayerChip extends StatelessWidget {
  const WHomePrayerChip({super.key, required this.label, required this.time, required this.style});

  final String label;
  final String time;
  final ({Color color, String emoji}) style;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 46.r,
          height: 46.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: style.color.withValues(alpha: 0.16)),
          child: Text(style.emoji, style: TextStyle(fontSize: 22.sp)),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
        ),
        SizedBox(height: 2.h),
        Text(
          time,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800, color: const Color(0xFF252525)),
        ),
      ],
    );
  }
}
