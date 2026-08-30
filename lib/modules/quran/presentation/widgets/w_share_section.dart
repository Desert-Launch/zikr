import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/brand_colors.dart';

/// A labelled group of rows in the share sheet — the sheet's only structural
/// element, so every section is spaced and cornered identically.
class WShareSection extends StatelessWidget {
  const WShareSection({
    required this.label,
    required this.children,
    super.key,
  });

  final String label;

  /// Rows of the group. [WShareRowDivider] separates them where they are a
  /// list of choices.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 8.h),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: context.brand.muted,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.brand.surface,
            borderRadius: BorderRadius.circular(14.r),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ],
    );
  }
}

/// The hairline between two rows of a group, inset the way a grouped list
/// insets it so the rule starts under the label rather than the edge.
class WShareRowDivider extends StatelessWidget {
  const WShareRowDivider({super.key});

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    indent: 14.w,
    endIndent: 14.w,
    color: context.brand.border.withValues(alpha: 0.5),
  );
}

/// One tappable row: a title on the leading edge, and whatever the row uses to
/// say what it holds on the trailing one.
class WShareRow extends StatelessWidget {
  const WShareRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.titleColor,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;

  /// Overrides the title's colour — used by rows that are an action rather
  /// than a setting, which read in the brand green.
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            if (leading != null) ...[leading!, SizedBox(width: 10.w)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? context.brand.onSurface,
                    ),
                  ),
                  if (sub != null && sub.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: context.brand.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[SizedBox(width: 10.w), trailing!],
          ],
        ),
      ),
    );
  }
}
