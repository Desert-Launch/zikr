import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/extension/build_context.dart';

/// The round tinted icon badge used at the start of every adhan settings row
/// (e.g. the notification bell).
class WAdhanIconCircle extends StatelessWidget {
  const WAdhanIconCircle({super.key, required this.icon, this.color = const Color(0xFF2F7E63)});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // `.r` inflates to ~68px against the tablet design size, which no longer
    // fits the compact tablet rows — pin it to the same badge WSettingsIcon uses.
    final isTab = context.isTablet;
    return Container(
      width: isTab ? 42 : 42.r,
      height: isTab ? 42 : 42.r,
      decoration: const BoxDecoration(color: Color(0xFFF1F4ED), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: isTab ? 22 : 24.r),
    );
  }
}
