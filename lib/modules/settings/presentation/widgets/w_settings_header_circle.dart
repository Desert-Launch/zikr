import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WSettingsHeaderCircle extends StatelessWidget {
  const WSettingsHeaderCircle({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.045),
          width: 4.r,
        ),
      ),
    );
  }
}
