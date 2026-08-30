import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/e_share_format.dart';
import 'package:quran/modules/quran/domain/services/share_text_builder.dart';
import 'package:quran/modules/quran/presentation/cubits/s_ayah_share.dart';

/// Whether the app is currently being read in Arabic. Decides the script the
/// verse numbers are set in and which name the app signs itself with.
bool get shareIsArabic => LocalizeAndTranslate.getLanguageCode() == 'ar';

/// The surah's name as the reader's language writes it, falling back to its
/// number while the metadata is still being read.
String shareSurahName(MSurah? surah, int number) {
  if (surah == null) return '$number';
  final name = shareIsArabic ? surah.arabic : surah.name;
  return name.isEmpty ? '$number' : name;
}

/// How one end of the range is labelled: `الأنعام: ٦٥`.
String shareAyahLabel(String surahName, int ayah) =>
    '$surahName: ${shareDigits(ayah, arabic: shareIsArabic)}';

/// The line the app signs a share with, above the link.
String shareViaLabel() => 'quran_share_via'.tr().replaceFirst(
  '{{app}}',
  shareIsArabic ? AppConfig.shareAppNameAr : AppConfig.shareAppNameEn,
);

/// The share button's label, counted the way the language counts.
///
/// Arabic has four shapes for this and gets all four — a button reading
/// "مشاركة ٢ آيات" is the kind of thing that tells a reader the app was
/// written in another language first.
String shareCountLabel(int count) {
  final key = switch (count) {
    1 => 'quran_share_cta_one',
    2 => 'quran_share_cta_two',
    >= 3 && <= 10 => 'quran_share_cta_few',
    _ => 'quran_share_cta_many',
  };
  return key.tr().replaceFirst(
    '{{count}}',
    shareDigits(count, arabic: shareIsArabic),
  );
}

/// The share's text, built from the sheet's current choices.
///
/// The one place the formatter is called from the UI, so the preview, the text
/// share and the caption that rides along with an image are always the same
/// string.
String buildShareTextFor(SAyahShare state) {
  final content = state.content;
  if (content == null) return '';
  return buildShareText(
    content: content,
    surahName: shareSurahName(content.surah, state.surah),
    viaLabel: shareViaLabel(),
    arabicDigits: shareIsArabic,
    stripTashkeel: state.format == EShareFormat.plainText,
    appBadge: state.appBadge,
  );
}
