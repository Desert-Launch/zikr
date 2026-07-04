import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/app_text_styles.dart';
import 'package:quran/core/widgets/w_gradient_app_bar.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/live/domain/entities/e_live_channel.dart';

/// Channel picker shown before the live player. The user chooses a Haramain
/// channel here; tapping a card opens [LiveRoutes.playerFor] for that channel,
/// so the player no longer needs an in-screen switcher.
class SNLivePicker extends StatelessWidget {
  const SNLivePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return WSharedScaffold(
      withSafeArea: false,
      padding: EdgeInsets.zero,
      body: Column(
        children: [
          WGradientAppBar(title: 'live_title'.tr()),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              physics: const BouncingScrollPhysics(),
              itemCount: ELiveChannel.all.length,
              separatorBuilder: (_, __) => SizedBox(height: 18.h),
              itemBuilder: (_, index) {
                final channel = ELiveChannel.all[index];
                return _ChannelCard(
                  channel: channel,
                  onTap: () => Modular.to.pushNamed(LiveRoutes.playerFor(channel.id)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A single tappable broadcast card — deep green gradient with a soft glow, a
/// decorative light bloom, a LIVE badge, the mosque title/subtitle, and a play
/// affordance.
class _ChannelCard extends StatelessWidget {
  const _ChannelCard({required this.channel, required this.onTap});

  final ELiveChannel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22.r);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: AppColorsLight.primary.withValues(alpha: 0.28), blurRadius: 18.r, offset: Offset(0, 8.h)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColorsLight.primary, AppColorsLight.primaryDark],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: radius,
            ),
            child: Stack(
              children: [
                // Decorative light bloom bleeding off the leading-top corner.
                Positioned(
                  top: -30.h,
                  left: -20.w,
                  child: Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.white.withValues(alpha: 0.14), Colors.white.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
                  child: Row(
                    children: [
                      _ChannelIcon(),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _LiveBadge(),
                            SizedBox(height: 8.h),
                            Text(
                              channel.titleKey.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.white18W700,
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              channel.subtitleKey.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.white12W400.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _PlayButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded translucent tile holding the broadcast icon.
class _ChannelIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54.w,
      height: 54.w,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Icon(Icons.live_tv_rounded, color: Colors.white, size: 28.sp),
    );
  }
}

/// White play affordance with a faint halo.
class _PlayButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
      child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30.sp),
    );
  }
}

/// Small red "LIVE" pill with a gently pulsing dot.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(6.w, 3.h, 9.w, 3.h),
      decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(7.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulsingDot(),
          SizedBox(width: 6.w),
          Text('live_badge'.tr(), style: AppTextStyles.white12W700),
        ],
      ),
    );
  }
}

/// A white dot that softly pulses to signal a live stream.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_controller),
      child: Container(
        width: 7.w,
        height: 7.w,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }
}
