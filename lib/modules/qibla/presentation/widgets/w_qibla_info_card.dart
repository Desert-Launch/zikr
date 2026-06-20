import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/qibla/presentation/widgets/qibla_digits.dart';

class WQiblaInfoCard extends StatelessWidget {
  const WQiblaInfoCard({
    super.key,
    required this.heading,
    required this.distanceKm,
    required this.green,
    required this.gold,
  });

  /// Live device compass heading in degrees (0..360), updates as it moves.
  final double heading;
  final double distanceKm;
  final Color green;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Bearing degree + cardinal name.
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${localizeQiblaDigits(heading.round().toString())}°',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  color: gold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                _cardinalName(heading),
                style: TextStyle(fontSize: 12.sp, color: context.brand.muted),
              ),
            ],
          ),
          SizedBox(width: 16.w),
          // Direction button.
          Container(
            width: 46.r,
            height: 46.r,
            decoration: BoxDecoration(
              color: green,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: green.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.navigation_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _cardinalName(double bearing) {
    const keys = [
      'qibla_dir_n',
      'qibla_dir_ne',
      'qibla_dir_e',
      'qibla_dir_se',
      'qibla_dir_s',
      'qibla_dir_sw',
      'qibla_dir_w',
      'qibla_dir_nw',
    ];
    final index = (((bearing % 360) + 22.5) ~/ 45) % 8;
    return keys[index].tr();
  }

  String _formatDistance(double km) {
    final withSep = km.round().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return localizeQiblaDigits(withSep);
  }
}
