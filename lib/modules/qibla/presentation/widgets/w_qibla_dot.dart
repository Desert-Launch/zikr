import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WQiblaDot extends StatelessWidget {
  const WQiblaDot({super.key, required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 9.r,
        height: 9.r,
        decoration: const BoxDecoration(
          color: Color(0xFFC9C5B8),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
