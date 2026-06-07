import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/extension/build_context.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';

/// Shared chrome for every auth screen, matching the design mockups: a soft
/// light canvas with a faint decorative ring in the top corner, an optional
/// circular back affordance, a centered title and an optional subtitle.
class WAuthScaffold extends StatelessWidget {
  const WAuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.showBack,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// Defaults to whether the navigator can pop.
  final bool? showBack;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final canBack = showBack ?? context.canGoBack;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: brand.background,
        body: Stack(
          children: [
            // Faint decorative ring anchored to the top corner.
            Positioned(
              top: -90.h,
              right: -70.w,
              child: Container(
                width: 240.r,
                height: 240.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: brand.primary.withValues(alpha: 0.06),
                    width: 28.r,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 28.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 44.h,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: canBack
                            ? _BackButton(color: brand.primary)
                            : null,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColorsLight.primary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.sp, color: brand.muted),
                      ),
                    ],
                    SizedBox(height: 32.h),
                    child,
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: CircleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: Modular.to.pop,
        child: Padding(
          padding: EdgeInsets.all(8.r),
          child: Icon(Icons.arrow_forward_rounded, color: color, size: 22.r),
        ),
      ),
    );
  }
}
