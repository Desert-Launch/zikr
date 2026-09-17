import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/entities/e_playback_options.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';
import 'package:quran/modules/quran/presentation/widgets/w_player_choice_row.dart';
import 'package:quran/modules/quran/presentation/widgets/w_player_range_form.dart';

/// The repeat card of the full player. Its contents follow the selected mode:
/// mode pills and a one-line hint are always there; the from–to form appears
/// in range mode; the count presets, per-ayah stepper (range/surah) and
/// after-finish toggle appear whenever a repeat is on; the auto-advance
/// switch closes the card.
///
/// Expects a [CBAudioPlayer] above it in the tree.
class WPlayerRepeatCard extends StatelessWidget {
  const WPlayerRepeatCard({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 4.h),
      decoration: BoxDecoration(
        color: brand.surfaceMuted,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(),
          SizedBox(height: 12.h),
          const _ModeSection(),
          const _RangeSection(),
          const _OptionsSection(),
          SizedBox(height: 8.h),
          Divider(height: 1, color: brand.border),
          const _AutoAdvanceRow(),
        ],
      ),
    );
  }
}

/// Icon + title, with a badge on the trailing edge summarising the active
/// repeat (`∞` or `×N`) so the setting reads at a glance even when the card
/// is scrolled past.
class _CardTitle extends StatelessWidget {
  const _CardTitle();

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Row(
      children: [
        Container(
          width: 30.r,
          height: 30.r,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: brand.primary.withValues(alpha: 0.12),
          ),
          child: Icon(Icons.repeat_rounded, size: 17.r, color: brand.primary),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            'player_repeat'.tr(),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: brand.onSurface,
            ),
          ),
        ),
        const _ActiveBadge(),
      ],
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAudioPlayer, SAudioPlayer>(
      buildWhen: (a, b) =>
          a.options.repeatMode != b.options.repeatMode ||
          a.options.repeatCount != b.options.repeatCount,
      builder: (context, state) {
        final opts = state.options;
        if (opts.repeatMode == RepeatMode.off) return const SizedBox.shrink();
        final brand = context.brand;
        final text = opts.repeatCount == 0
            ? 'player_repeat_infinite'.tr()
            : '×${opts.repeatCount}';
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: brand.primary,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );
      },
    );
  }
}

/// The four mode pills plus a muted one-liner saying what the mode does.
class _ModeSection extends StatelessWidget {
  const _ModeSection();

  static String _hint(RepeatMode mode) => switch (mode) {
    RepeatMode.off => 'player_repeat_hint_off'.tr(),
    RepeatMode.singleAyah => 'player_repeat_hint_single'.tr(),
    RepeatMode.range => 'player_repeat_hint_range'.tr(),
    RepeatMode.surah => 'player_repeat_hint_surah'.tr(),
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAudioPlayer, SAudioPlayer>(
      buildWhen: (a, b) => a.options.repeatMode != b.options.repeatMode,
      builder: (context, state) {
        final cubit = BlocProvider.of<CBAudioPlayer>(context);
        final mode = state.options.repeatMode;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WPlayerChoiceRow<RepeatMode>(
              selected: mode,
              onChanged: cubit.setRepeatMode,
              choices: [
                PlayerChoice(
                  value: RepeatMode.off,
                  label: 'player_repeat_off'.tr(),
                  icon: Icons.close_rounded,
                ),
                PlayerChoice(
                  value: RepeatMode.singleAyah,
                  label: 'player_repeat_single'.tr(),
                  icon: Icons.repeat_one_rounded,
                ),
                PlayerChoice(
                  value: RepeatMode.range,
                  label: 'player_repeat_range'.tr(),
                  icon: Icons.compare_arrows_rounded,
                ),
                PlayerChoice(
                  value: RepeatMode.surah,
                  label: 'player_repeat_surah'.tr(),
                  icon: Icons.menu_book_rounded,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                _hint(mode),
                style: TextStyle(fontSize: 11.sp, color: context.brand.muted),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The from–to form, mounted only in range mode so its local state starts
/// from whatever range is active at that moment.
class _RangeSection extends StatelessWidget {
  const _RangeSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAudioPlayer, SAudioPlayer>(
      buildWhen: (a, b) => a.options.repeatMode != b.options.repeatMode,
      builder: (context, state) {
        final isRange = state.options.repeatMode == RepeatMode.range;
        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: isRange
              ? Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: const WPlayerRangeForm(),
                )
              : const SizedBox(width: double.infinity),
        );
      },
    );
  }
}

/// Repeat count presets, then the per-ayah stepper (range/surah only) beside
/// the after-finish toggle. Collapsed while repeat is off.
class _OptionsSection extends StatelessWidget {
  const _OptionsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAudioPlayer, SAudioPlayer>(
      buildWhen: (a, b) =>
          a.options.repeatMode != b.options.repeatMode ||
          a.options.repeatCount != b.options.repeatCount ||
          a.options.ayahRepeat != b.options.ayahRepeat ||
          a.options.afterRepeat != b.options.afterRepeat,
      builder: (context, state) {
        final cubit = BlocProvider.of<CBAudioPlayer>(context);
        final opts = state.options;
        final mode = opts.repeatMode;
        // Per-ayah repeat only means something for a multi-ayah unit.
        final perAyah = mode == RepeatMode.range || mode == RepeatMode.surah;
        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: mode == RepeatMode.off
              ? const SizedBox(width: double.infinity)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 14.h),
                    _Labeled(
                      label: 'player_repeat_count'.tr(),
                      child: _CountPresets(
                        value: opts.repeatCount,
                        onChanged: cubit.setRepeatCount,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (perAyah) ...[
                          Expanded(
                            child: _Labeled(
                              label: 'player_ayah_repeat'.tr(),
                              child: WPlayerStepper(
                                value: '${opts.ayahRepeat}',
                                onDecrement: opts.ayahRepeat <= 1
                                    ? null
                                    : () => cubit.setAyahRepeat(
                                        opts.ayahRepeat - 1,
                                      ),
                                onIncrement:
                                    opts.ayahRepeat >=
                                        EPlaybackOptions.maxAyahRepeat
                                    ? null
                                    : () => cubit.setAyahRepeat(
                                        opts.ayahRepeat + 1,
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                        ],
                        Expanded(
                          child: _Labeled(
                            label: 'player_repeat_after'.tr(),
                            child: WPlayerChoiceRow<EAfterRepeat>(
                              selected: opts.afterRepeat,
                              onChanged: cubit.setAfterRepeat,
                              choices: [
                                PlayerChoice(
                                  value: EAfterRepeat.stop,
                                  label: 'player_after_stop'.tr(),
                                ),
                                PlayerChoice(
                                  value: EAfterRepeat.continueNext,
                                  label: 'player_after_continue'.tr(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// Tap-once repeat counts. `0` is the cubit's "infinite". A persisted count
/// outside the presets is slotted in so it stays visible and selected.
class _CountPresets extends StatelessWidget {
  const _CountPresets({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const _presets = <int>[1, 2, 3, 5, 10];

  @override
  Widget build(BuildContext context) {
    final finite = value > 0 && !_presets.contains(value)
        ? ([..._presets, value]..sort())
        : _presets;
    return WPlayerChoiceRow<int>(
      selected: value,
      onChanged: onChanged,
      choices: [
        for (final n in finite) PlayerChoice(value: n, label: '$n'),
        PlayerChoice(value: 0, label: 'player_repeat_infinite'.tr()),
      ],
    );
  }
}

/// Small muted caption above a control.
class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: context.brand.muted,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        child,
      ],
    );
  }
}

class _AutoAdvanceRow extends StatelessWidget {
  const _AutoAdvanceRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAudioPlayer, SAudioPlayer>(
      buildWhen: (a, b) =>
          a.options.autoAdvanceSurah != b.options.autoAdvanceSurah,
      builder: (context, state) {
        final cubit = BlocProvider.of<CBAudioPlayer>(context);
        final brand = context.brand;
        final on = state.options.autoAdvanceSurah;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: cubit.toggleAutoAdvanceSurah,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Icon(
                    Icons.skip_next_rounded,
                    size: 20.r,
                    color: on ? brand.primary : brand.muted,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'player_auto_advance'.tr(),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: brand.onSurface,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: on,
                      activeTrackColor: brand.primary,
                      thumbColor: WidgetStateProperty.all(
                        on ? Colors.white : Colors.grey.shade400,
                      ),
                      onChanged: (_) => cubit.toggleAutoAdvanceSurah(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
