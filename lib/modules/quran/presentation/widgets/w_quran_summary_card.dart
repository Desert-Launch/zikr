import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WQuranSummaryCard extends StatelessWidget {
  const WQuranSummaryCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 19.r),
              SizedBox(height: 12.h),
              Text(
                value,
                style: TextStyle(color: color, fontSize: 13.sp),
              ),
              SizedBox(height: 5.h),
              Text(
                label,
                style: TextStyle(fontSize: 8.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
