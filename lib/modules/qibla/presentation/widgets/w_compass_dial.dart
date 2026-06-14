import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/modules/qibla/presentation/widgets/w_compass_rose.dart';
import 'package:quran/modules/qibla/presentation/widgets/w_kaaba_core.dart';

class WCompassDial extends StatelessWidget {
  const WCompassDial({
    super.key,
    required this.heading,
    required this.qiblaAngle,
    required this.green,
    required this.gold,
  });

  final double heading;
  final double qiblaAngle;
  final Color green;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final size = 300.r;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer neumorphic plate.
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFBFAF6), Color(0xFFE8E5DC)],
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x55000000), blurRadius: 24, offset: Offset(0, 10)),
                BoxShadow(color: Color(0xCCFFFFFF), blurRadius: 18, offset: Offset(-8, -8)),
              ],
            ),
          ),
          // Rotating rose: cardinals, ticks and intermediate dots.
          Transform.rotate(
            angle: -heading * math.pi / 180.0,
            child: SizedBox(width: size, height: size, child: const WCompassRose()),
          ),
          // Qibla pointer — orbits to point toward Mecca.
          Transform.rotate(
            angle: qiblaAngle,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 20.h),
                child: Icon(Icons.navigation_rounded, color: gold, size: 24.r),
              ),
            ),
          ),
          // Static Kaaba center.
          WKaabaCore(green: green, gold: gold),
        ],
      ),
    );
  }
}
