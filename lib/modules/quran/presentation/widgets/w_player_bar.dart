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
  const WPlayerBar({super.key, required this.state, required this.cubit});

  final SAudioPlayer state;
  final CBAudioPlayer cubit;

  @override
  Widget build(BuildContext context) {
    final ayah = state.currentAyah;
    return Row(
      children: [
        Container(
          width: 40.r,
          height: 40.r,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColorsLight.primary, AppColorsLight.accent],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.headphones_rounded, color: Colors.white),
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
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
              ),
              SizedBox(height: 2.h),
              if (state.duration > Duration.zero)
                LinearProgressIndicator(
                  value:
                      state.position.inMilliseconds /
                      state.duration.inMilliseconds.clamp(1, 1 << 31),
                  minHeight: 3.h,
                  backgroundColor: context.brand.border,
                  color: AppColorsLight.primary,
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: cubit.previous,
        ),
        IconButton(
          icon: Icon(
            state.isPlaying
                ? Icons.pause_circle_filled_rounded
                : Icons.play_circle_fill_rounded,
            color: AppColorsLight.primary,
            size: 32.r,
          ),
          onPressed: state.isPlaying ? cubit.pause : cubit.resume,
        ),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: cubit.next,
        ),
      ],
    );
  }
}
