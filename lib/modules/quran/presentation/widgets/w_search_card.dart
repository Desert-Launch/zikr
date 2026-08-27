import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/brand_colors.dart';

/// The one card every search result sits in — text hits, pages, surahs and
/// arba' alike, so a result list reads as a single stack rather than three
/// different designs.
///
/// [Material] under the [InkWell] rather than a plain [Container] so the ripple
/// is actually visible: a card that paints its own opaque background hides the
/// splash the ink well draws beneath it.
class WSearchCard extends StatelessWidget {
  const WSearchCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.highlight = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  /// Tints the border and background with the brand green — used for the row
  /// that answers the query most directly.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final radius = BorderRadius.circular(14.r);
    return Material(
      color: highlight ? brand.primary.withValues(alpha: 0.05) : brand.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: highlight
                  ? brand.primary.withValues(alpha: 0.28)
                  : brand.border,
            ),
          ),
          padding: padding ?? EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
          child: child,
        ),
      ),
    );
  }
}
