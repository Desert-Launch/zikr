import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/data/models/m_reciter.dart';

class WReciterTile extends StatelessWidget {
  const WReciterTile({
    required this.reciter,
    required this.isActive,
    required this.isPreviewing,
    required this.onTap,
    required this.onPreview,
    this.previewLoading = false,
    this.previewDuration,
    super.key,
  });

  final MReciter reciter;
  final bool isActive;

  /// This reciter's sample is loading or playing.
  final bool isPreviewing;

  /// The sample is still loading/buffering (only meaningful while previewing).
  final bool previewLoading;

  /// Length of the playing sample, for the progress ring; `null` until known.
  final Duration? previewDuration;

  final VoidCallback onTap;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      elevation: 1,
      // Blended to an opaque colour: a translucent Card lets its own elevation
      // shadow show through and reads as grey.
      color: isPreviewing
          ? Color.alphaBlend(
              AppColorsLight.primary.withValues(alpha: 0.08),
              Theme.of(context).colorScheme.surfaceContainerLow,
            )
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(
          color: isActive ? AppColorsLight.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  color: AppColorsLight.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.person_rounded,
                    color: AppColorsLight.primary, size: 24.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reciter.arabic.isEmpty ? reciter.name : reciter.arabic,
                      style: GoogleFonts.amiri(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: context.brand.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: switch (reciter.style) {
                              ReciterStyle.mujawwad => AppColorsLight.primary.withAlpha(30),
                              ReciterStyle.muallim => AppColorsLight.accent.withAlpha(40),
                              ReciterStyle.murattal => AppColors.surfaceLightGreen,
                            },
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            reciter.style.labelKey.tr(),
                            style: TextStyle(fontSize: 10.sp, color: context.brand.muted),
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '~${reciter.estimatedSizeMb} MB',
                          style: TextStyle(fontSize: 11.sp, color: context.brand.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isActive)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.check_circle, color: AppColorsLight.primary),
                ),
              SizedBox(width: 4.w),
              _PreviewButton(
                isPreviewing: isPreviewing,
                loading: previewLoading,
                duration: previewDuration,
                onPressed: onPreview,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round play/stop control for a reciter's sample: a play glyph at rest, a
/// spinner while the clip loads, then a stop glyph inside a ring that fills
/// over the clip's length.
class _PreviewButton extends StatelessWidget {
  const _PreviewButton({
    required this.isPreviewing,
    required this.loading,
    required this.duration,
    required this.onPressed,
  });

  final bool isPreviewing;
  final bool loading;
  final Duration? duration;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final size = 40.r;
    final clip = duration;
    final Widget content;
    if (!isPreviewing) {
      content = Icon(Icons.play_arrow_rounded, color: AppColorsLight.primary, size: 24.r);
    } else if (loading) {
      content = SizedBox.square(
        dimension: 20.r,
        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    } else {
      content = Stack(
        alignment: Alignment.center,
        children: [
          if (clip != null)
            // Restarts from empty whenever a new clip (or reciter) starts.
            TweenAnimationBuilder<double>(
              key: ValueKey(clip),
              tween: Tween(begin: 0, end: 1),
              duration: clip,
              builder: (_, value, _) => SizedBox.square(
                dimension: size - 6.r,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 2.5,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),
          Icon(Icons.stop_rounded, color: Colors.white, size: 20.r),
        ],
      );
    }

    return Tooltip(
      message: (isPreviewing ? 'reciter_picker_preview_stop' : 'reciter_picker_preview').tr(),
      child: Material(
        color: isPreviewing ? AppColorsLight.primary : AppColorsLight.primary.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
