import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' show Bidi;
import 'package:quran/core/theme/app_text_styles.dart';

/// A zekr body laid out paragraph by paragraph.
///
/// The English text interleaves the Arabic with a transliteration and a
/// translation, so each blank-line separated paragraph takes its own direction
/// and size: Arabic large and right-to-left, Latin at a reading size. A plain
/// Arabic zekr is a single paragraph and renders as before.
class WAzkarZekrText extends StatelessWidget {
  const WAzkarZekrText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final paragraphs = text
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, paragraph) in paragraphs.indexed) ...[
          if (index > 0) SizedBox(height: 14.h),
          _Paragraph(text: paragraph),
        ],
      ],
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final rtl = Bidi.detectRtlDirectionality(text);
    return Text(
      text,
      textAlign: TextAlign.center,
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      style: rtl
          ? AppTextStyles.ink24W400.copyWith(fontSize: 24.sp, height: 1.9)
          : AppTextStyles.ink16W400.copyWith(fontSize: 16.sp, height: 1.7),
    );
  }
}
