import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/azkar/presentation/cubits/cb_azkar_audio.dart';
import 'package:quran/modules/azkar/presentation/cubits/s_azkar_audio.dart';
import 'package:quran/modules/azkar/presentation/widgets/w_azkar_reader_sheet.dart';
import 'package:quran/modules/settings/presentation/widgets/w_settings_row.dart';

/// القارئ المفضل — the settings row for the globally preferred adhkar reader.
///
/// Lives in the azkar module rather than settings so there is exactly one place
/// that knows how to render and change this preference; the settings screen
/// just references it, the way it references the salawat sheet.
class WAzkarPreferredReaderRow extends StatefulWidget {
  const WAzkarPreferredReaderRow({super.key});

  @override
  State<WAzkarPreferredReaderRow> createState() =>
      _WAzkarPreferredReaderRowState();
}

class _WAzkarPreferredReaderRowState extends State<WAzkarPreferredReaderRow> {
  late final CBAzkarAudio _audio = Modular.get<CBAzkarAudio>();

  @override
  void initState() {
    super.initState();
    // Parses readers.json only — the per-reader mapping files stay unread.
    _audio.loadCatalogue();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBAzkarAudio, SAzkarAudio>(
      bloc: _audio,
      buildWhen: (prev, curr) =>
          prev.preferredReaderId != curr.preferredReaderId ||
          prev.readers != curr.readers,
      builder: (context, state) {
        final isArabic = LocalizeAndTranslate.getLanguageCode() == 'ar';
        return WSettingsRow(
          icon: Icons.record_voice_over_outlined,
          title: 'azkar_audio_preferred_reader'.tr(),
          subtitle: 'azkar_audio_preferred_reader_hint'.tr(),
          value:
              state.preferredReader?.displayName(isArabic) ??
              'azkar_audio_reader_auto'.tr(),
          onTap: () => _pick(context, state),
        );
      },
    );
  }

  Future<void> _pick(BuildContext context, SAzkarAudio state) async {
    final picked = await WAzkarReaderSheet.show(
      context,
      readers: state.readers,
      selectedId: state.preferredReaderId,
      title: 'azkar_audio_preferred_reader'.tr(),
    );
    if (picked == null) return;
    await _audio.setPreferredReader(
      picked == WAzkarReaderSheet.autoValue ? null : picked,
    );
  }
}
