import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/extension/build_context.dart';

class WSettingsIcon extends StatelessWidget {
  const WSettingsIcon({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isTab = context.isTablet;
    return Container(
      width: isTab ? 42 : 38.r,
      height: isTab ? 42 : 38.r,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF1F4ED),
      ),
      child: Icon(icon, color: const Color(0xFF2F7E63), size: isTab ? 22 : 19.r),
    );
  }
}
