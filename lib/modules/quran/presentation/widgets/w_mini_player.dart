import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';
import 'package:quran/modules/quran/presentation/widgets/w_full_player.dart';
import 'package:quran/modules/quran/presentation/widgets/w_player_bar.dart';

/// Floating playback bar shown whenever the audio player is active.
class WMiniPlayer extends StatelessWidget {
  const WMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: Modular.get<CBAudioPlayer>(),
      child: BlocBuilder<CBAudioPlayer, SAudioPlayer>(
        builder: (context, state) {
          final isActive =
              state.currentAyah != null && state.status != PlayerStatus.idle;
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
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        decoration: BoxDecoration(
          color: context.brand.surface,
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
            child: WPlayerBar(state: state, cubit: cubit, onStop: cubit.stop),
          ),
        ),
      ),
    );
  }
}
