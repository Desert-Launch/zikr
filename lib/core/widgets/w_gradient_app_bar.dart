import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/theme/app_colors.dart';

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
    this.backIcon = Icons.arrow_forward_rounded,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Optional trailing icons (rendered on the end/left side in RTL).
  final List<Widget>? actions;

  /// Defaults to `Modular.to.pop()` when omitted.
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
            // Faint decorative circles, like the reference design.
            PositionedDirectional(
              top: -34.h,
              end: -24.w,
              child: _Bubble(size: 120.r),
            ),
            PositionedDirectional(
              bottom: -46.h,
              start: 30.w,
              child: _Bubble(size: 96.r),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 16.h),
                // Headers always read right-to-left (back on the right, actions
                // on the left) regardless of the screen's ambient direction.
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    children: [
                      if (showBack)
                        IconButton(
                          onPressed: onBack ?? Modular.to.pop,
                          icon: Icon(backIcon, color: Colors.white),
                        )
                      else
                        SizedBox(width: 48.w),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (subtitle != null) ...[
                              SizedBox(height: 2.h),
                              Text(
                                subtitle ?? '',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 9.sp,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }
}
