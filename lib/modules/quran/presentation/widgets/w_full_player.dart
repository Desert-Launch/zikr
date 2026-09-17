import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/entities/e_sleep_timer.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reciter.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reciter.dart';
import 'package:quran/modules/quran/presentation/widgets/w_player_repeat_card.dart';
import 'package:quran/modules/quran/presentation/widgets/w_reciter_sheet.dart';

/// Expanded playback UI. Opens as a modal bottom sheet from the mini-player.
///
/// Includes: a compact now-playing card, position scrubber, transport controls,
/// compact chips for reciter / speed / sleep timer, and the repeat card
/// ([WPlayerRepeatCard]) with its mode-driven range form and options.
class WFullPlayer extends StatelessWidget {
  const WFullPlayer({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WFullPlayer(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: Modular.get<CBAudioPlayer>(),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.66,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: context.brand.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
              children: [
                const _Grip(),
                SizedBox(height: 10.h),
                const _Header(),
                SizedBox(height: 14.h),
                const _ArtworkBlock(),
                SizedBox(height: 14.h),
                const _Scrubber(),
                const _Transport(),
                SizedBox(height: 16.h),
                // Secondary controls grouped as compact chips.
                const _ReciterChip(),
                SizedBox(height: 10.h),
                Row(
                  children: const [
                    Expanded(child: _SpeedChip()),
                    SizedBox(width: 10),
                    Expanded(child: _SleepChip()),
                  ],
                ),
                SizedBox(height: 12.h),
                const WPlayerRepeatCard(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Grip extends StatelessWidget {
  const _Grip();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: context.brand.border,
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'player_now_playing'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
              letterSpacing: 0.4,
              color: context.brand.muted,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.expand_more_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _ArtworkBlock extends StatelessWidget {
  const _ArtworkBlock();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAudioPlayer, SAudioPlayer>(
      buildWhen: (a, b) => a.currentAyah?.key != b.currentAyah?.key,
      builder: (context, state) {
        final ayah = state.currentAyah;
        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A5639), Color(0xFF0E6B47), Color(0xFF12826E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: AppColorsLight.primary.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ayah == null
              ? SizedBox(height: 84.h)
              : _NowPlayingCard(ref: ayah),
        );
      },
    );
  }
}

/// Compact "now playing" card: a gold book emblem, the surah name, and a gold
/// ayah-number star — laid out horizontally to keep the card short.
class _NowPlayingCard extends StatefulWidget {
  const _NowPlayingCard({required this.ref});

  final ParamAyahRef ref;

  @override
  State<_NowPlayingCard> createState() => _NowPlayingCardState();
}

class _NowPlayingCardState extends State<_NowPlayingCard> {
  String _surahName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _NowPlayingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ref.surah != widget.ref.surah) _load();
  }

  Future<void> _load() async {
    final res = await Modular.get<RQuran>().getSurah(widget.ref.surah);
    if (!mounted) return;
    res.fold(
      (_) {},
      (s) =>
          setState(() => _surahName = s.arabic.isNotEmpty ? s.arabic : s.name),
    );
  }

  static String _arabicDigits(int n) {
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return '$n'.split('').map((c) {
      final d = int.tryParse(c);
      return d == null ? c : eastern[d];
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final name = _surahName.isEmpty
        ? '${'player_surah_label'.tr()} ${widget.ref.surah}'
        : _surahName;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          // Emblem — the focal "cover art".
          Container(
            width: 54.r,
            height: 54.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 28.r,
              color: AppColorsLight.accent,
            ),
          ),
          SizedBox(width: 14.w),
          // Surah name + ayah label.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'الآية ${_arabicDigits(widget.ref.ayah)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          // Ayah marker.
          SizedBox(
            width: 40.r,
            height: 40.r,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 40.r,
                  color: AppColorsLight.accent,
                ),
                Text(
                  _arabicDigits(widget.ref.ayah),
                  style: TextStyle(
                    color: AppColorsLight.primaryDark,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Scrubber extends StatelessWidget {
  const _Scrubber();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAudioPlayer, SAudioPlayer>(
      buildWhen: (a, b) => a.position != b.position || a.duration != b.duration,
      builder: (context, state) {
        final cubit = BlocProvider.of<CBAudioPlayer>(context);
        final maxMs = state.duration.inMilliseconds;
        final posMs = state.position.inMilliseconds.clamp(0, maxMs);
        final sliderMax = maxMs <= 0 ? 1.0 : maxMs.toDouble();
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4.h,
                trackShape: const RoundedRectSliderTrackShape(),
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.r),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 16.r),
                activeTrackColor: AppColorsLight.primary,
                inactiveTrackColor: context.brand.border,
                thumbColor: AppColorsLight.primary,
                overlayColor: AppColorsLight.primary.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: posMs.toDouble().clamp(0, sliderMax),
                max: sliderMax,
                onChanged: maxMs <= 0
                    ? null
                    : (v) => cubit.seekTo(Duration(milliseconds: v.toInt())),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(state.position),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: context.brand.muted,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    _fmt(state.duration),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: context.brand.muted,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${two(m)}:${two(s)}';
  }
}

class _Transport extends StatelessWidget {
  const _Transport();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAudioPlayer, SAudioPlayer>(
      buildWhen: (a, b) =>
          a.status != b.status ||
          a.queueIndex != b.queueIndex ||
          a.queue.length != b.queue.length,
      builder: (context, state) {
        final cubit = BlocProvider.of<CBAudioPlayer>(context);
        final isPlaying = state.isPlaying;
        final isLoading = state.isLoadingLike;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              iconSize: 30.r,
              onPressed: cubit.previous,
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            IconButton(
              iconSize: 28.r,
              onPressed: () =>
                  cubit.seekTo(state.position - const Duration(seconds: 10)),
              icon: const Icon(Icons.replay_10_rounded),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColorsLight.primary, AppColorsLight.accent],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColorsLight.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 44.r,
                color: Colors.white,
                onPressed: isLoading
                    ? null
                    : (isPlaying ? cubit.pause : cubit.resume),
                icon: isLoading
                    ? SizedBox(
                        width: 22.r,
                        height: 22.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
              ),
            ),
            IconButton(
              iconSize: 28.r,
              onPressed: () =>
                  cubit.seekTo(state.position + const Duration(seconds: 10)),
              icon: const Icon(Icons.forward_10_rounded),
            ),
            IconButton(
              iconSize: 30.r,
              onPressed: cubit.next,
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ],
        );
      },
    );
  }
}

/// Compact pill used for the secondary controls (reciter / speed / sleep).
class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: active
            ? AppColorsLight.primary.withValues(alpha: 0.08)
            : context.brand.surfaceMuted,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: active
              ? AppColorsLight.primary.withValues(alpha: 0.4)
              : context.brand.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18.r,
            color: active ? AppColorsLight.primary : context.brand.muted,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10.sp, color: context.brand.muted),
                ),
                SizedBox(height: 1.h),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? AppColorsLight.primary
                        : context.brand.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: content,
    );
  }
}

/// Shows the active reciter and opens [WReciterSheet] to switch.
class _ReciterChip extends StatefulWidget {
  const _ReciterChip();

  @override
  State<_ReciterChip> createState() => _ReciterChipState();
}

class _ReciterChipState extends State<_ReciterChip> {
  final CBReciter _reciter = Modular.get<CBReciter>();

  @override
  void initState() {
    super.initState();
    if (_reciter.state.all.isEmpty) _reciter.load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBReciter, SReciter>(
      bloc: _reciter,
      buildWhen: (a, b) =>
          a.activeId != b.activeId || a.all.length != b.all.length,
      builder: (context, state) {
        var name = '';
        for (final r in state.all) {
          if (r.id == state.activeId) {
            name = r.arabic.isNotEmpty ? r.arabic : r.name;
            break;
          }
        }
        return _OptionChip(
          icon: Icons.record_voice_over_rounded,
          label: 'player_reciter'.tr(),
          value: name.isEmpty ? '—' : name,
          onTap: () => WReciterSheet.show(context),
        );
      },
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip();

  static const _stops = <double>[0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  static String _fmt(double v) =>
      '${v.toStringAsFixed(v == v.roundToDouble() ? 1 : 2)}x';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAudioPlayer, SAudioPlayer>(
      buildWhen: (a, b) => a.options.speed != b.options.speed,
      builder: (context, state) {
        final cubit = BlocProvider.of<CBAudioPlayer>(context);
        final speed = state.options.speed.clamp(0.5, 2.0);
        return PopupMenuButton<double>(
          initialValue: speed,
          onSelected: cubit.setSpeed,
          tooltip: 'player_speed'.tr(),
          itemBuilder: (_) => [
            for (final s in _stops)
              PopupMenuItem<double>(value: s, child: Text(_fmt(s))),
          ],
          child: _OptionChip(
            icon: Icons.speed_rounded,
            label: 'player_speed'.tr(),
            value: _fmt(speed),
            active: speed != 1.0,
          ),
        );
      },
    );
  }
}

class _SleepChip extends StatelessWidget {
  const _SleepChip();

  String _label(ESleepTimer t) => switch (t) {
    ESleepTimer.off => 'player_sleep_off'.tr(),
    ESleepTimer.min5 => 'player_sleep_5'.tr(),
    ESleepTimer.min10 => 'player_sleep_10'.tr(),
    ESleepTimer.min15 => 'player_sleep_15'.tr(),
    ESleepTimer.min30 => 'player_sleep_30'.tr(),
    ESleepTimer.min60 => 'player_sleep_60'.tr(),
    ESleepTimer.endOfAyah => 'player_sleep_end_ayah'.tr(),
    ESleepTimer.endOfSurah => 'player_sleep_end_surah'.tr(),
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAudioPlayer, SAudioPlayer>(
      buildWhen: (a, b) => a.sleepTimer != b.sleepTimer,
      builder: (context, state) {
        final cubit = BlocProvider.of<CBAudioPlayer>(context);
        final active = state.sleepTimer != ESleepTimer.off;
        return PopupMenuButton<ESleepTimer>(
          initialValue: state.sleepTimer,
          onSelected: cubit.setSleepTimer,
          tooltip: 'player_sleep'.tr(),
          itemBuilder: (_) => [
            for (final t in ESleepTimer.values)
              PopupMenuItem<ESleepTimer>(value: t, child: Text(_label(t))),
          ],
          child: _OptionChip(
            icon: Icons.bedtime_outlined,
            label: 'player_sleep'.tr(),
            value: _label(state.sleepTimer),
            active: active,
          ),
        );
      },
    );
  }
}
