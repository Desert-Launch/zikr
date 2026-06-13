import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WSettingsIcon extends StatelessWidget {
  const WSettingsIcon({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38.r,
      height: 38.r,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF1F4ED),
      ),
      child: Icon(icon, color: const Color(0xFF2F7E63), size: 19.r),
    );
  }
}
