import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Extension on EdgeInsets for quick responsive scaling
extension ResponsiveEdgeInsets on EdgeInsets {
  EdgeInsets get responsive => EdgeInsets.only(
        left: left.w,
        right: right.w,
        top: top.h,
        bottom: bottom.h,
      );
}

/// Extension on num for clamped font sizing
extension ClampedFont on num {
  /// Scaled font with upper bound to prevent giant text on tablets
  double spCapped(double max) => toDouble().sp.clamp(0, max);

  /// Scaled font with both min and max bounds
  double spClamp(double min, double max) => toDouble().sp.clamp(min, max);

  /// Scaled radius with upper bound to prevent balloon corners on tablets
  double rCapped(double max) => toDouble().r.clamp(0, max);
}
