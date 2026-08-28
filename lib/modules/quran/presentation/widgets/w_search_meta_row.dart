import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_card.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_page_pill.dart';

/// A one-line search result: an icon or number badge, a bold title with a muted
/// second line, and the page it lands on.
///
/// Shared by every result that names a place in the mushaf rather than a verse
/// — a page, a surah from a numeric query, a surah matched by name — so those
/// rows stay one design.
class WSearchMetaRow extends StatelessWidget {
  const WSearchMetaRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
    this.leadingBadge,
    this.page,
    this.highlight = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Shown instead of [icon] when the row is itself numbered (a surah).
  final String? leadingBadge;
  final int? page;

  /// Tints the card with the brand green — on for the row that answers the
  /// query most directly.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final badge = leadingBadge;
    final page = this.page;
    return WSearchCard(
      onTap: onTap,
      highlight: highlight,
      child: Row(
        children: [
          Container(
            width: 34.r,
            height: 34.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: brand.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: badge != null
                ? Text(
                    badge,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: brand.primary,
                    ),
                  )
                : Icon(icon, size: 18.r, color: brand.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: brand.onSurface,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.sp, color: brand.muted),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          if (page != null) WSearchPagePill(page: page),
        ],
      ),
    );
  }
}
