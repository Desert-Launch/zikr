import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/utils/helper/nav_helper.dart';
import 'package:quran/core/widgets/w_localize_rotation.dart';

/// Shared green-gradient header used across the app.
///
/// Layout is always right-to-left (the app is Arabic-first), regardless of the
/// host screen's ambient [Directionality]:
///   • right side → back button
///   • center     → [title] and optional [subtitle]
///   • left side  → optional [actions] (e.g. a sound/volume icon)
///
/// Use it as the `appBar` of a [Scaffold]/`WSharedScaffold`, or place it at the
/// top of a `CustomScrollView` via `SliverToBoxAdapter`. It implements
/// [PreferredSizeWidget] so it can be passed directly to `Scaffold.appBar`.
class WGradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WGradientAppBar({
    required this.title,
    this.subtitle,
    this.actions,
    this.onBack,
    this.showBack = true,
    this.backIcon = Icons.arrow_back_rounded,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Optional trailing icons (rendered on the end/left side in RTL).
  final List<Widget>? actions;

  /// Defaults to [NavHelper.back] when omitted — a pop, or Home when this
  /// screen is the whole stack (opened from a notification on a cold start).
  final VoidCallback? onBack;
  final bool showBack;
  final IconData backIcon;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 96.h : 116.h);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColorsLight.primary, AppColorsLight.primaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
        child: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 16.h),
                // Back leads, actions trail — the row inherits the ambient
                // direction, so it reads right-to-left in Arabic and
                // left-to-right in English without being pinned either way.
                child: Row(
                  children: [
                    if (showBack)
                      IconButton(
                        onPressed: onBack ?? NavHelper.back,
                        // The glyph itself has to be mirrored: Flutter icons
                        // don't flip with the layout direction.
                        icon: WLocalizeRotation(
                          reverse: true,
                          child: Icon(backIcon, color: Colors.white),
                        ),
                      )
                    else
                      SizedBox(width: 48.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.white24W400,
                          ),
                          if (subtitle != null) ...[
                            SizedBox(height: 2.h),
                            Text(
                              subtitle ?? '',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.white12W400.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (actions != null && actions!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions ?? [],
                      )
                    else
                      SizedBox(width: 48.w),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
