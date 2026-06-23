import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';

/// Playback controls row (artwork, current ayah, progress, transport buttons).
///
/// Reused by the floating [WMiniPlayer] and embedded at the bottom of the ayah
/// action sheet, so the same controls appear wherever playback is shown.
class WPlayerBar extends StatelessWidget {
  const WPlayerBar({
    super.key,
    required this.state,
    required this.cubit,
    this.onStop,
  });

  final SAudioPlayer state;
  final CBAudioPlayer cubit;

  /// When provided, a stop/dismiss button is shown (used by the mini player).
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final ayah = state.currentAyah;
    final loading = state.isLoadingLike;
    final maxMs = state.duration.inMilliseconds;
    final progress = maxMs <= 0
        ? 0.0
        : (state.position.inMilliseconds / maxMs).clamp(0.0, 1.0);
    return Row(
      children: [
        // Artwork — shows a spinner while the track is loading/buffering.
        Container(
          width: 44.r,
          height: 44.r,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColorsLight.primary, AppColorsLight.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: loading
              ? SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(Icons.headphones_rounded, color: Colors.white, size: 22.r),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ayah == null ? '—' : 'الآية ${ayah.ayah} · سورة ${ayah.surah}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp),
              ),
              SizedBox(height: 6.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: loading ? null : progress,
                  minHeight: 4.h,
                  backgroundColor: context.brand.border,
                  color: AppColorsLight.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 4.w),
        IconButton(
          visualDensity: VisualDensity.compact,
          color: context.brand.onSurface,
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: cubit.previous,
        ),
        // Primary play/pause — a filled disc so the main action stands out.
        GestureDetector(
          onTap: loading ? null : (state.isPlaying ? cubit.pause : cubit.resume),
          child: Container(
            width: 40.r,
            height: 40.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColorsLight.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColorsLight.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24.r,
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          color: context.brand.onSurface,
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: cubit.next,
        ),
        if (onStop != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            color: context.brand.muted,
            icon: const Icon(Icons.close_rounded),
            onPressed: onStop,
          ),
      ],
    );
  }
}
