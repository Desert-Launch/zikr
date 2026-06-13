import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Gradient rounded-square box holding a tinted white SVG glyph. Gold or green
/// gradient depending on [color].
class WHomeIconBox extends StatelessWidget {
  const WHomeIconBox({super.key, required this.icon, required this.color});

  final String icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isGold = color == const Color(0xFFD6A72C);

    return Container(
      width: 56.r,
      height: 56.r,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isGold ? const [Color(0xFFD4AF37), Color(0xFFD4AF37)] : const [Color(0xFF0D7E5E), Color(0xFF0A6349)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 7, offset: Offset(0, 3))],
      ),
      padding: EdgeInsets.all(14.r),
      child: SvgPicture.asset(icon, colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn)),
    );
  }
}
