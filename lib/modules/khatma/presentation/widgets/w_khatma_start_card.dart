import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Call-to-action "start a new khatma" card on the empty screen.
class WKhatmaStartCard extends StatelessWidget {
  const WKhatmaStartCard({super.key, required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD6A72C);
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE0E7E2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 16.sp, color: const Color(0xFF1F2A24)),
            ),
            SizedBox(width: 12.w),
            Container(
              width: 52.r,
              height: 52.r,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [gold, Color(0xFFA8851C)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
