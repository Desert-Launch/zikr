import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/azkar/data/models/m_azkar_reader.dart';
import 'package:quran/modules/azkar/presentation/cubits/cb_azkar_audio.dart';
import 'package:quran/modules/azkar/presentation/cubits/s_azkar_audio.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_reader_sheet.dart';

/// The audio strip under the counter card: which reader is speaking, a way to
/// change them, and — for a whole-sitting recording — transport plus a scrubber.
///
/// It states the reader plainly, and says so when the voice playing is a
/// fallback rather than the one the user chose. Silently substituting a
/// different sheikh would be the easy thing to build and the wrong thing to do.
class WAzkarAudioBar extends StatelessWidget {
  const WAzkarAudioBar({
    required this.adhkarId,
    required this.title,
    required this.categoryId,
    required this.categoryTitle,
    super.key,
  });

  final String adhkarId;
  final String title;
  final String categoryId;
  final String categoryTitle;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';

    return BlocBuilder<CBAzkarAudio, SAzkarAudio>(
      builder: (context, state) {
        final hasDhikrAudio = state.hasAudioFor(adhkarId);
        final hasSitting = state.hasCategoryRecording(categoryId);
        if (!hasDhikrAudio && !hasSitting) return const SizedBox.shrink();

        final cubit = context.read<CBAzkarAudio>();
        final activeHere =
            state.isActiveAdhkar(adhkarId) || state.isActiveCategory(categoryId);
        final reader = activeHere
            ? state.playingReader
            : state.preferredReader;

        return Container(
          margin: EdgeInsets.only(top: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: brand.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: brand.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.record_voice_over_rounded,
                    size: 18.r,
                    color: brand.primary,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'azkar_audio_reader'.tr(),
                          style: TextStyle(fontSize: 10.sp, color: brand.muted),
                        ),
                        Text(
                          reader?.displayName(isArabic) ??
                              'azkar_audio_reader_auto'.tr(),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: brand.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickReader(context, cubit, state),
                    child: Text(
                      'azkar_audio_change_reader'.tr(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: brand.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (activeHere && state.isFallbackReader)
                _Note(
                  icon: Icons.info_outline_rounded,
                  color: brand.muted,
                  text:
                      '${'azkar_audio_fallback_note'.tr()} '
                      '${state.playingReader?.displayName(isArabic) ?? ''}',
                ),
              if (state.status == AzkarAudioStatus.unavailable && activeHere)
                _Note(
                  icon: Icons.cloud_off_rounded,
                  color: brand.error,
                  text: 'azkar_audio_offline_unavailable'.tr(),
                ),
              if (hasSitting) ...[
                Divider(height: 16.h, color: brand.border),
                _SittingRow(
                  categoryId: categoryId,
                  categoryTitle: categoryTitle,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickReader(
    BuildContext context,
    CBAzkarAudio cubit,
    SAzkarAudio state,
  ) async {
    // Ask only for readers that have this dhikr — offering a voice with nothing
    // to play would just be a dead end.
    final readers = await cubit.readersForAdhkar(adhkarId);
    final forCategory = await cubit.readersForCategory(categoryId);
    final merged = <String, MAzkarReader>{
      for (final r in <MAzkarReader>[...readers, ...forCategory]) r.id: r,
    };
    if (!context.mounted) return;
    final picked = await WAzkarReaderSheet.show(
      context,
      readers: merged.values.toList(growable: false),
      selectedId: state.preferredReaderId,
    );
    if (picked == null) return;
    await cubit.setPreferredReader(
      picked == WAzkarReaderSheet.autoValue ? null : picked,
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 14.r, color: color),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11.sp, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Transport for the whole-sitting recording, with a scrubber fed by the
/// player's position stream so only this row rebuilds while it ticks.
class _SittingRow extends StatelessWidget {
  const _SittingRow({required this.categoryId, required this.categoryTitle});

  final String categoryId;
  final String categoryTitle;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final cubit = context.read<CBAzkarAudio>();
    return BlocBuilder<CBAzkarAudio, SAzkarAudio>(
      buildWhen: (prev, curr) =>
          prev.activeCategoryId != curr.activeCategoryId ||
          prev.status != curr.status,
      builder: (context, state) {
        final isActive = state.isActiveCategory(categoryId);
        final isPlaying = state.isPlayingCategory(categoryId);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Semantics(
                  button: true,
                  label: isPlaying
                      ? 'azkar_audio_a11y_stop'.tr()
                      : 'azkar_audio_a11y_play_sitting'.tr(),
                  child: IconButton(
                    onPressed: () => cubit.toggleCategory(
                      categoryId,
                      title: categoryTitle,
                    ),
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      size: 30.r,
                      color: brand.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'azkar_audio_play_sitting'.tr(),
                    style: TextStyle(fontSize: 12.sp, color: brand.onSurface),
                  ),
                ),
              ],
            ),
            if (isActive)
              StreamBuilder<Duration>(
                stream: cubit.positionStream,
                builder: (context, snapshot) {
                  final total = cubit.duration ?? Duration.zero;
                  final position = snapshot.data ?? Duration.zero;
                  final max = total.inMilliseconds.toDouble();
                  if (max <= 0) return const SizedBox.shrink();
                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.h,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 6.r,
                          ),
                        ),
                        child: Slider(
                          value: position.inMilliseconds
                              .clamp(0, total.inMilliseconds)
                              .toDouble(),
                          max: max,
                          activeColor: brand.primary,
                          onChanged: (value) => cubit.seek(
                            Duration(milliseconds: value.round()),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _clock(position),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: brand.muted,
                            ),
                          ),
                          Text(
                            _clock(total),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: brand.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }

  String _clock(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
