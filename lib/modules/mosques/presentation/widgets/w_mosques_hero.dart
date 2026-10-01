import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/assets/assets.gen.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';

/// Top of the nearby-mosques screen: the green header over a mosque photo,
/// with a pin badge in the middle and a "view on map" pill in the corner.
class WMosquesHero extends StatelessWidget {
  const WMosquesHero({required this.subtitle, this.onViewOnMap, super.key});

  /// The header's location line.
  final String subtitle;

  /// Opens the area in a map app. The pill is hidden while null (no fix yet).
  final VoidCallback? onViewOnMap;

  @override
  Widget build(BuildContext context) {
    final onMap = onViewOnMap;
    return Stack(
      children: [
        // Fills behind the header as well, so the photo shows through the
        // header's rounded bottom corners instead of the page background.
        Positioned.fill(
          child: Image.asset(
            Assets.images.adhanBackgroundImage.path,
            fit: BoxFit.cover,
            // Frames the dome and minarets below the header.
            alignment: const Alignment(0, 0.1),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WGradientAppBar(
              title: 'mosques_title'.tr(),
              subtitle: subtitle,
              subtitleIcon: Icons.location_on_outlined,
              centerTitle: false,
            ),
            SizedBox(
              height: 190.h,
              child: Stack(
                children: [
                  const Center(child: _PinBadge()),
                  if (onMap != null)
                    PositionedDirectional(
                      end: 12.w,
                      bottom: 14.h,
                      child: _ViewOnMapPill(onTap: onMap),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinBadge extends StatelessWidget {
  const _PinBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64.r,
      height: 64.r,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.location_on_outlined,
        size: 34.r,
        color: context.brand.primary,
      ),
    );
  }
}

class _ViewOnMapPill extends StatelessWidget {
  const _ViewOnMapPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = context.brand.primary;
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.near_me_outlined, size: 15.r, color: primary),
              SizedBox(width: 6.w),
              Text(
                'mosques_view_on_map'.tr(),
                style: AppTextStyles.ink12W500.copyWith(color: primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
