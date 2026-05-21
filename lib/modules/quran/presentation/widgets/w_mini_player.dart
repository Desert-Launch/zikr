import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';
import 'package:quran/modules/quran/presentation/widgets/w_full_player.dart';

/// Floating playback bar shown whenever the audio player is active.
class WMiniPlayer extends StatelessWidget {
  const WMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: Modular.get<CBAudioPlayer>(),
      child: BlocBuilder<CBAudioPlayer, SAudioPlayer>(
        builder: (context, state) {
          final isActive = state.currentAyah != null && state.status != PlayerStatus.idle;
          return AnimatedSlide(
            offset: Offset(0, isActive ? 0 : 1.2),
            duration: const Duration(milliseconds: 200),
            child: AnimatedOpacity(
              opacity: isActive ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: !isActive
                  ? const SizedBox.shrink()
                  : _Bar(state: state, cubit: Modular.get<CBAudioPlayer>()),
            ),
          );
        },
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.state, required this.cubit});
  final SAudioPlayer state;
  final CBAudioPlayer cubit;

  @override
  Widget build(BuildContext context) {
    final ayah = state.currentAyah;
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () => WFullPlayer.show(context),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            child: Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.brandPurple, AppColors.brandPurpleAccent],
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
                          value: state.position.inMilliseconds /
                              state.duration.inMilliseconds.clamp(1, 1 << 31),
                          minHeight: 3.h,
                          backgroundColor: AppColors.neutralBorderLight,
                          color: AppColors.brandPurple,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  onPressed: cubit.previous,
                ),
                IconButton(
                  icon: Icon(state.isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                    color: AppColors.brandPurple, size: 32.r),
                  onPressed: state.isPlaying ? cubit.pause : cubit.resume,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: cubit.next,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: cubit.stop,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
