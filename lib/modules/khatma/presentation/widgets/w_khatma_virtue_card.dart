import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Virtue/verse card on the empty khatma screen.
class WKhatmaVirtueCard extends StatelessWidget {
  const WKhatmaVirtueCard({
    super.key,
    required this.title,
    required this.verse,
    required this.reference,
  });

  final String title;
  final String verse;
  final String reference;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD6A72C);
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 18.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EBCB),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: gold.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: const BoxDecoration(
              color: gold,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star_rounded, color: Colors.white, size: 26.r),
          ),
          SizedBox(height: 10.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              color: const Color(0xFF9A7B2E),
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: 60.w,
            height: 1,
            color: gold.withValues(alpha: 0.4),
          ),
          SizedBox(height: 12.h),
          Text(
            verse,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              height: 1.9,
              color: const Color(0xFF4A3D1E),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            reference,
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF9A7B2E),
            ),
          ),
        ],
      ),
    );
  }
}
