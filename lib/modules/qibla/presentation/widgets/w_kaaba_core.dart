import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:quran/core/assets/assets.gen.dart';

class WKaabaCore extends StatelessWidget {
  const WKaabaCore({super.key, required this.green, required this.gold});

  final Color green;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116.r,
      height: 116.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white, width: 6),
        boxShadow: [BoxShadow(color: green.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: SvgPicture.asset(Assets.icons.hexagon.path),
    );
  }
}
