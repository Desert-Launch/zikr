import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/home/presentation/widgets/w_home_icon_box.dart';

/// Square-ish grid tile: icon on top, title + subtitle below, all aligned to the
/// leading edge (right in Arabic, left in English).
class WHomeFeatureCard extends StatelessWidget {
  const WHomeFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.route,
    this.onTap,
    this.comingSoon = false,
  });

  final String icon;
  final String title;
  final String subtitle;
  final Color color;

  /// Route pushed on tap. Ignored when [onTap] is supplied.
  final String? route;

  /// Overrides the default route push — e.g. to open a picker sheet instead.
  final VoidCallback? onTap;

  /// A feature that isn't ready yet: the tile carries a "coming soon" badge
  /// and doesn't open anything. Keep [route] set so turning this off is all
  /// it takes to ship it.
  final bool comingSoon;

  VoidCallback? get _handleTap {
    if (comingSoon) return null;
    if (onTap != null) return onTap;
    final r = route;
    if (r != null) return () => Modular.to.pushNamed(r);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: _handleTap,
      child: Container(
        // Four of these share a row on tablet, so a tile is roughly a quarter
        // of the width there. `150.h` stretches to ~228px against that — a
        // narrow tower. A fixed logical height keeps the tile near-square, the
        // same trick the settings rows use to survive the taller design grid.
        height: context.isTablet ? 176 : 150.h,
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WHomeIconBox(icon: icon, color: color),
                if (comingSoon) ...[const Spacer(), const _ComingSoonBadge()],
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.ink18W500,
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.grey12W400,
            ),
          ],
        ),
      ),
    );
  }
}

/// Gold pill in the tile's top corner, across from the icon.
class _ComingSoonBadge extends StatelessWidget {
  const _ComingSoonBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: const Color(0xFFD6A72C),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        'home_coming_soon'.tr(),
        style: AppTextStyles.white12W700.copyWith(fontSize: 10.sp, height: 1.6),
      ),
    );
  }
}
