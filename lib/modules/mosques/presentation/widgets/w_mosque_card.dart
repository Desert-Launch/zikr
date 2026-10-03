import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_app_button.dart';
import 'package:quran/modules/mosques/domain/entities/e_mosque.dart';

/// One row of the nearby-mosques list: rank, name, address and distance, with
/// a directions button underneath.
class WMosqueCard extends StatelessWidget {
  const WMosqueCard({
    required this.rank,
    required this.mosque,
    required this.onDirections,
    super.key,
  });

  /// 1-based position on the list (1 = nearest).
  final int rank;
  final EMosque mosque;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: brand.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: brand.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RankBadge(rank: rank),
              SizedBox(width: 12.w),
              Expanded(child: _Details(mosque: mosque)),
              SizedBox(width: 8.w),
              Text(
                _distanceLabel(mosque.distanceMeters),
                style: AppTextStyles.ink12W500.copyWith(color: brand.primary),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Divider(height: 1, thickness: 1, color: brand.border.withValues(alpha: 0.6)),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: WAppButton(
              title: 'mosques_directions'.tr(),
              onTap: onDirections,
              isExpanded: false,
              width: 96.w,
              height: 32.h,
              radius: 16.r,
              withShadow: false,
              style: AppTextStyles.white12W500,
              leading: Icon(Icons.near_me_outlined, size: 15.r, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Metres up to a kilometre (rounded to 10 m — finer is GPS noise), then
  /// kilometres with one decimal, whole kilometres from 10 km on.
  static String _distanceLabel(double meters) {
    if (meters < 1000) {
      final m = math.max(10, (meters / 10).round() * 10);
      return 'mosques_distance_m'.tr().replaceFirst('{{m}}', '$m');
    }
    final km = meters / 1000;
    final value = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
    return 'mosques_distance_km'.tr().replaceFirst('{{km}}', value);
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      width: 40.r,
      height: 40.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [brand.primary, brand.primaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Text('$rank', style: AppTextStyles.white16W500),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.mosque});

  final EMosque mosque;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mosque.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.ink14W500.copyWith(color: brand.onSurface),
        ),
        if (mosque.address.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14.r, color: brand.muted),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  mosque.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.grey12W400.copyWith(color: brand.muted),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
