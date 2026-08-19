import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/responsive/responsive_extensions.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/theme/brand_colors.dart';

/// The in-app twin of a system notification: the card that slides down from the
/// top when a scheduled alert fires while the app is open.
///
/// Shown through `AppAlert.notification`, which mounts it in the Navigator's
/// overlay — so it rides above whatever screen, sheet or dialog is open rather
/// than belonging to any one route.
///
/// Direction-agnostic: the row inherits the ambient [Directionality], so the
/// icon leads on the right in Arabic and on the left in English.
class WInAppNotification extends StatelessWidget {
  const WInAppNotification({
    required this.title,
    required this.body,
    this.payloadType = '',
    this.onTap,
    super.key,
  });

  final String title;
  final String body;

  /// `NotificationPayload.type` — picks the leading icon. An unknown or empty
  /// type falls back to a generic bell.
  final String payloadType;

  /// Opens what the real notification would have opened. Null leaves the card
  /// inert (it still auto-dismisses).
  final VoidCallback? onTap;

  /// The face each kind of alert wears, so a glance is enough to tell an azkar
  /// reminder from a prayer one without reading the title.
  static IconData iconFor(String payloadType) => switch (payloadType) {
    'prayer' || 'adhan' => Icons.mosque_rounded,
    'azkar' => Icons.auto_stories_rounded,
    'quran' => Icons.menu_book_rounded,
    'khatma' => Icons.event_available_rounded,
    'hourly' || 'salawat' => Icons.favorite_rounded,
    'reminder' => Icons.alarm_rounded,
    _ => Icons.notifications_active_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final radius = BorderRadius.circular(18.rCapped(22));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Material(
        color: brand.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                _Badge(icon: iconFor(payloadType), color: brand.primary),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.ink14W700,
                      ),
                      if (body.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.grey12W400,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tinted circle carrying the alert's icon.
class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = 40.rCapped(48);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 22.rCapped(26), color: color),
    );
  }
}
