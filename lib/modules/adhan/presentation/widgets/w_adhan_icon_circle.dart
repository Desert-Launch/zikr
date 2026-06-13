import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The round tinted icon badge used at the start of every adhan settings row
/// (e.g. the notification bell).
class WAdhanIconCircle extends StatelessWidget {
  const WAdhanIconCircle({
    super.key,
    required this.icon,
    this.color = const Color(0xFF2F7E63),
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42.r,
      height: 42.r,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F4ED),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 21.r),
    );
  }
}
