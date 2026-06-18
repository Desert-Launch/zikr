import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_playback_options.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';

/// Expanded playback UI. Opens as a modal bottom sheet from the mini-player.
///
/// Includes: position scrubber, transport controls, repeat-mode toggle,
/// playback-speed slider (0.5x–2x), and a from/to range picker that calls
/// `CBAudioPlayer.playRange`.
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
        initialChildSize: 0.65,
        minChildSize: 0.5,
        maxChildSize: 0.65,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: context.brand.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
              children: const [
                _Grip(),
                SizedBox(height: 12),
                _Header(),
                SizedBox(height: 24),
                _ArtworkBlock(),
                SizedBox(height: 16),
                _Scrubber(),
                SizedBox(height: 8),
                _Transport(),
                SizedBox(height: 16),
                // Phase 1 smoke test: speed persists across restarts.
                // Repeat/range rows land in Phase 4.
                _SpeedRow(),
                // _RepeatRow(),
                // _RangePicker(),
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
        decoration: BoxDecoration(color: context.brand.border, borderRadius: BorderRadius.circular(4.r)),
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
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.sp),
          ),
        ),
        IconButton(icon: const Icon(Icons.expand_more_rounded), onPressed: () => Navigator.of(context).pop()),
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
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 160.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColorsLight.primary, AppColorsLight.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: ayah == null ? const SizedBox.shrink() : _AyahText(ref: ayah),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              ayah == null ? '—' : '${'player_surah_label'.tr()} ${ayah.surah}',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18.sp),
            ),
            SizedBox(height: 2.h),
            Text(
              ayah == null ? '' : '${'player_ayah_label'.tr()} ${ayah.ayah}',
              style: TextStyle(color: context.brand.muted, fontSize: 13.sp),
            ),
          ],
        );
      },
    );
  }
}

class _AyahText extends StatefulWidget {
  const _AyahText({required this.ref});

  final ParamAyahRef ref;

  @override
  State<_AyahText> createState() => _AyahTextState();
}

class _AyahTextState extends State<_AyahText> {
  late Future<String> _text = _load();

  Future<String> _load() => Modular.get<DSLocalQuran>().ayahText(widget.ref);

  @override
  void didUpdateWidget(covariant _AyahText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ref.key != widget.ref.key) {
      _text = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _text,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final text = snapshot.data ?? '';
        return SingleChildScrollView(
          child: Text(
            text.isEmpty ? '—' : text,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w600, height: 1.8),
          ),
        );
      },
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
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                trackHeight: 3.h,
                activeTrackColor: AppColorsLight.primary,
                inactiveTrackColor: context.brand.border,
                thumbColor: AppColorsLight.primary,
              ),
              child: Slider(
                value: posMs.toDouble().clamp(0, sliderMax),
                max: sliderMax,
                onChanged: maxMs <= 0 ? null : (v) => cubit.seekTo(Duration(milliseconds: v.toInt())),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fmt(state.position),
                    style: TextStyle(fontSize: 11.sp, color: context.brand.muted),
                  ),
                  Text(
                    _fmt(state.duration),
                    style: TextStyle(fontSize: 11.sp, color: context.brand.muted),
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
      buildWhen: (a, b) => a.status != b.status || a.queueIndex != b.queueIndex || a.queue.length != b.queue.length,
      builder: (context, state) {
        final cubit = BlocProvider.of<CBAudioPlayer>(context);
        final isPlaying = state.isPlaying;
        final isLoading = state.isLoadingLike;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(iconSize: 30.r, onPressed: cubit.previous, icon: const Icon(Icons.skip_previous_rounded)),
            IconButton(
              iconSize: 28.r,
              onPressed: () => cubit.seekTo(state.position - const Duration(seconds: 10)),
              icon: const Icon(Icons.replay_10_rounded),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColorsLight.primary, AppColorsLight.accent]),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                iconSize: 44.r,
                color: Colors.white,
                onPressed: isLoading ? null : (isPlaying ? cubit.pause : cubit.resume),
                icon: isLoading
                    ? SizedBox(
                        width: 22.r,
                        height: 22.r,
                        child: const CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              ),
            ),
            IconButton(
              iconSize: 28.r,
              onPressed: () => cubit.seekTo(state.position + const Duration(seconds: 10)),
              icon: const Icon(Icons.forward_10_rounded),
            ),
            IconButton(iconSize: 30.r, onPressed: cubit.next, icon: const Icon(Icons.skip_next_rounded)),
          ],
        );
      },
    );
  }
}

class _RepeatRow extends StatelessWidget {
  const _RepeatRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAudioPlayer, SAudioPlayer>(
      buildWhen: (a, b) => a.options.repeatMode != b.options.repeatMode,
      builder: (context, state) {
        final cubit = BlocProvider.of<CBAudioPlayer>(context);
        final mode = state.options.repeatMode;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            children: [
              Icon(Icons.repeat_rounded, size: 18.r, color: context.brand.muted),
              SizedBox(width: 8.w),
              Text(
                'player_repeat'.tr(),
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              SegmentedButton<RepeatMode>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11.sp)),
                ),
                segments: [
                  ButtonSegment(value: RepeatMode.off, label: Text('player_repeat_off'.tr())),
                  ButtonSegment(value: RepeatMode.singleAyah, label: Text('player_repeat_single'.tr())),
                  ButtonSegment(value: RepeatMode.range, label: Text('player_repeat_range'.tr())),
                ],
                selected: {mode},
                onSelectionChanged: (s) => cubit.setRepeatMode(s.first),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpeedRow extends StatelessWidget {
  const _SpeedRow();

  static const _stops = <double>[0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAudioPlayer, SAudioPlayer>(
      buildWhen: (a, b) => a.options.speed != b.options.speed,
      builder: (context, state) {
        final cubit = BlocProvider.of<CBAudioPlayer>(context);
        final speed = state.options.speed.clamp(0.5, 2.0);
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Icon(Icons.speed_rounded, size: 18.r, color: context.brand.muted),
                  SizedBox(width: 8.w),
                  Text(
                    'player_speed'.tr(),
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColorsLight.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${speed.toStringAsFixed(speed == speed.roundToDouble() ? 1 : 2)}x',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColorsLight.primary),
                    ),
                  ),
                ],
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3.h,
                activeTrackColor: AppColorsLight.primary,
                thumbColor: AppColorsLight.primary,
                inactiveTrackColor: context.brand.border,
              ),
              child: Slider(
                value: speed,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                label: '${speed.toStringAsFixed(2)}x',
                onChanged: (v) {
                  final snapped = _stops.reduce((a, b) => (a - v).abs() < (b - v).abs() ? a : b);
                  cubit.setSpeed(snapped);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RangePicker extends StatefulWidget {
  const _RangePicker();

  @override
  State<_RangePicker> createState() => _RangePickerState();
}

class _RangePickerState extends State<_RangePicker> {
  int? _surah;
  int? _fromAyah;
  int? _toAyah;
  MSurah? _selected;
  List<MSurah> _all = const [];

  @override
  void initState() {
    super.initState();
    _load();
    final current = Modular.get<CBAudioPlayer>().state.currentAyah;
    if (current != null) {
      _surah = current.surah;
      _fromAyah = current.ayah;
    }
  }

  Future<void> _load() async {
    final res = await Modular.get<RQuran>().getSurahs();
    if (!mounted) return;
    res.fold((_) {}, (list) {
      setState(() {
        _all = list;
        if (_surah != null) {
          _selected = list.firstWhere((s) => s.number == _surah, orElse: () => list.first);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final ayahCount = _selected?.totalAyah ?? 0;
    return Container(
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: context.brand.background, borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 18.r, color: context.brand.muted),
              SizedBox(width: 8.w),
              Text(
                'player_range_title'.tr(),
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          DropdownButtonFormField<int>(
            initialValue: _surah,
            isExpanded: true,
            hint: Text('player_range_surah_hint'.tr(), style: TextStyle(fontSize: 12.sp)),
            decoration: _dec('player_range_surah'.tr()),
            items: _all
                .map(
                  (s) => DropdownMenuItem<int>(
                    value: s.number,
                    child: Text(
                      '${s.number}. ${s.arabic.isNotEmpty ? s.arabic : s.name}',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() {
              _surah = v;
              _selected = _all.firstWhere((s) => s.number == v, orElse: () => _all.first);
              _fromAyah = 1;
              _toAyah = _selected?.totalAyah ?? 1;
            }),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _fromAyah,
                  decoration: _dec('player_range_from'.tr()),
                  items: List.generate(ayahCount, (i) => i + 1)
                      .map(
                        (n) => DropdownMenuItem(
                          value: n,
                          child: Text('$n', style: TextStyle(fontSize: 13.sp)),
                        ),
                      )
                      .toList(),
                  onChanged: ayahCount == 0 ? null : (v) => setState(() => _fromAyah = v),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _toAyah,
                  decoration: _dec('player_range_to'.tr()),
                  items: List.generate(ayahCount, (i) => i + 1)
                      .map(
                        (n) => DropdownMenuItem(
                          value: n,
                          child: Text('$n', style: TextStyle(fontSize: 13.sp)),
                        ),
                      )
                      .toList(),
                  onChanged: ayahCount == 0 ? null : (v) => setState(() => _toAyah = v),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColorsLight.primary,
                padding: EdgeInsets.symmetric(vertical: 10.h),
              ),
              onPressed: _canPlay() ? _playRange : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                'player_range_play'.tr(),
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canPlay() {
    final s = _surah;
    final from = _fromAyah;
    final to = _toAyah;
    return s != null && from != null && to != null && from <= to;
  }

  void _playRange() {
    final s = _surah!;
    final from = _fromAyah!;
    final to = _toAyah!;
    Modular.get<CBAudioPlayer>().playRange(ParamAyahRef(surah: s, ayah: from), ParamAyahRef(surah: s, ayah: to));
    Navigator.of(context).pop();
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(fontSize: 11.sp),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.r),
      borderSide: BorderSide(color: context.brand.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.r),
      borderSide: BorderSide(color: context.brand.border),
    ),
  );
}
