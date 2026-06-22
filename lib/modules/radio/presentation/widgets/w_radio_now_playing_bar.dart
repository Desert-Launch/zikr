import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/modules/radio/presentation/cubits/cb_radio_player.dart';
import 'package:quran/modules/radio/presentation/cubits/s_radio_player.dart';

/// Pinned bottom bar showing the currently playing station with transport
/// controls. Rendered only when a station is loaded.
class WRadioNowPlayingBar extends StatelessWidget {
  const WRadioNowPlayingBar({super.key, required this.state});

  static const _green = Color(0xFF007A58);

  final SRadioPlayer state;

  @override
  Widget build(BuildContext context) {
    final station = state.current;
    if (station == null) return const SizedBox.shrink();

    final isArabic = Directionality.of(context) == TextDirection.rtl;
    final player = context.read<CBRadioPlayer>();
    final statusLabel = _statusLabel(state.status);

    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Text(
              station.flag ?? '📻',
              style: TextStyle(fontSize: 22.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    station.displayName(isArabic: isArabic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.white16W700,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.white12W400,
                  ),
                ],
              ),
            ),
            _RoundIcon(
              icon: state.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              busy: state.isBusy,
              onTap: () => player.toggle(station),
            ),
            SizedBox(width: 8.w),
            _RoundIcon(
              icon: Icons.stop_rounded,
              busy: false,
              onTap: player.stop,
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(RadioPlayerStatus status) {
    switch (status) {
      case RadioPlayerStatus.loading:
      case RadioPlayerStatus.buffering:
        return 'radio_buffering'.tr();
      case RadioPlayerStatus.playing:
        return 'radio_on_air'.tr();
      case RadioPlayerStatus.paused:
        return 'radio_paused'.tr();
      case RadioPlayerStatus.error:
        return 'radio_error'.tr();
      case RadioPlayerStatus.idle:
        return 'radio_stopped'.tr();
    }
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.busy, required this.onTap});

  final IconData icon;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onTap,
      child: Container(
        width: 38.w,
        height: 38.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: busy
            ? SizedBox(
                width: 18.w,
                height: 18.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white, size: 22.r),
      ),
    );
  }
}
