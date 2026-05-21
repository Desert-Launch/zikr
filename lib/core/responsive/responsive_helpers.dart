import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Device type detection — reusable everywhere
class DeviceType {
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  static bool isLargeTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  static bool isSmallPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;
}

/// Central responsive configuration for the entire app.
class AppResponsive {
  /// Device type detection
  static bool isTablet(BuildContext context) => DeviceType.isTablet(context);
  static bool isLargeTablet(BuildContext context) => DeviceType.isLargeTablet(context);

  /// Returns different values for phone vs tablet
  static T adaptive<T>(BuildContext context, {required T phone, required T tablet}) {
    return isTablet(context) ? tablet : phone;
  }

  /// Screen-aware horizontal padding.
  /// Phone: 16px | Tablet: 48px | Large tablet: 80px
  static EdgeInsets screenPadding(BuildContext context) {
    if (isLargeTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 80);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 48);
    } else {
      return const EdgeInsets.symmetric(horizontal: 16);
    }
  }

  /// Max width for single-column content (forms, chat, card lists)
  static double maxContentWidth(BuildContext context) {
    if (isLargeTablet(context)) return 700;
    if (isTablet(context)) return 600;
    return double.infinity;
  }

  /// Max width for wide content (grids, dashboards)
  static double maxWideContentWidth(BuildContext context) {
    if (isLargeTablet(context)) return 960;
    if (isTablet(context)) return 800;
    return double.infinity;
  }

  /// Grid column count based on available width
  static int gridColumns(BuildContext context, {double minItemWidth = 160}) {
    final width = MediaQuery.of(context).size.width;
    return (width / minItemWidth).floor().clamp(1, 6);
  }
}

/// Generic adaptive value — returns different values for phone vs tablet
T adaptive<T>(BuildContext context, {required T phone, required T tablet}) {
  return DeviceType.isTablet(context) ? tablet : phone;
}

/// Clamped font size — scales with .sp but respects min/max bounds
double clampedFontSize(double base, {double? min, double? max}) {
  final scaled = base.sp;
  return scaled.clamp(min ?? 0, max ?? double.infinity);
}
