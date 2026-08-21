import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/azkar/presentation/cubits/cb_azkar_audio.dart';
import 'package:quran/modules/azkar/presentation/cubits/s_azkar_audio.dart';

/// The small play/pause control that sits on a dhikr.
///
/// Renders nothing at all when no reader has this dhikr, so the counter card
/// looks exactly as it did before wherever there is no recording to offer.
/// Tapping only ever touches the player — the repetition counter is untouched.
class WAzkarAudioButton extends StatelessWidget {
  const WAzkarAudioButton({
    required this.adhkarId,
    required this.title,
    required this.color,
    this.size,
    super.key,
  });

  final String adhkarId;
  final String title;
  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAzkarAudio, SAzkarAudio>(
      // Rebuild only on the three things this button draws: whether audio
      // exists, whether *this* dhikr is loaded, and the transport status.
      buildWhen: (prev, curr) =>
          prev.hasAudioFor(adhkarId) != curr.hasAudioFor(adhkarId) ||
          prev.activeAdhkarId != curr.activeAdhkarId ||
          prev.status != curr.status,
      builder: (context, state) {
        if (!state.hasAudioFor(adhkarId)) return const SizedBox.shrink();

        final isActive = state.isActiveAdhkar(adhkarId);
        final isPlaying = state.isPlayingAdhkar(adhkarId);
        final isLoading = isActive && state.status == AzkarAudioStatus.loading;
        final diameter = size ?? 40.r;
        final reader = isActive ? state.playingReader : state.preferredReader;
        final readerName = reader?.displayName(
          LocalizeAndTranslate.getLanguageCode() == 'ar',
        );

        return Semantics(
          button: true,
          label: isPlaying
              ? 'azkar_audio_a11y_stop'.tr()
              : (readerName == null
                    ? 'azkar_audio_a11y_play'.tr()
                    : '${'azkar_audio_a11y_play_with'.tr()} $readerName'),
          child: Tooltip(
            message: readerName ?? 'azkar_audio_play'.tr(),
            child: InkWell(
              onTap: () => context.read<CBAzkarAudio>().toggleAdhkar(
                adhkarId,
                title: title,
              ),
              customBorder: const CircleBorder(),
              child: Container(
                width: diameter,
                height: diameter,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? color
                      : color.withValues(alpha: 0.10),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: isLoading
                    ? SizedBox(
                        width: diameter * 0.42,
                        height: diameter * 0.42,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isActive ? Colors.white : color,
                          ),
                        ),
                      )
                    : Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: diameter * 0.55,
                        color: isActive ? Colors.white : color,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
