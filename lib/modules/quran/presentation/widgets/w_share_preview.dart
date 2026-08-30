import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_ayah_share.dart';
import 'package:quran/modules/quran/presentation/cubits/s_ayah_share.dart';
import 'package:quran/modules/quran/presentation/widgets/share_labels.dart';
import 'package:quran/modules/quran/presentation/widgets/w_share_image_card.dart';

/// What the share will look like, shown live above the choices that shape it.
///
/// It is not only a courtesy. The card is captured straight out of this
/// preview, and a [RepaintBoundary] can only be captured once it has actually
/// been painted — so the picture being on screen is what makes the picture
/// possible.
class WSharePreview extends StatelessWidget {
  const WSharePreview({required this.boundaryKey, required this.height, super.key});

  /// Key on the boundary the sheet captures. Only attached in image mode.
  final GlobalKey boundaryKey;

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: BlocBuilder<CBAyahShare, SAyahShare>(
        buildWhen: (a, b) =>
            a.content != b.content ||
            a.format != b.format ||
            a.appBadge != b.appBadge,
        builder: (context, state) {
          if (state.content == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: SingleChildScrollView(
              child: state.isImage
                  ? _ImagePreview(boundaryKey: boundaryKey, state: state)
                  : _TextPreview(state: state),
            ),
          );
        },
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.boundaryKey, required this.state});

  final GlobalKey boundaryKey;
  final SAyahShare state;

  @override
  Widget build(BuildContext context) {
    final content = state.content;
    if (content == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) => RepaintBoundary(
        key: boundaryKey,
        child: WShareImageCard(
          content: content,
          surahName: shareSurahName(content.surah, state.surah),
          arabicDigits: shareIsArabic,
          appBadge: state.appBadge,
          // 1:1 with the preview, so what the reader sees is the file that
          // leaves — clamped so a tablet does not render a card twice the
          // width a phone would.
          width: constraints.maxWidth.clamp(300.0, 420.0),
        ),
      ),
    );
  }
}

class _TextPreview extends StatelessWidget {
  const _TextPreview({required this.state});

  final SAyahShare state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.brand.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.brand.border),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Text(
        buildShareTextFor(state),
        textDirection: TextDirection.rtl,
        style: GoogleFonts.amiri(
          fontSize: 14.sp,
          height: 1.8,
          color: context.brand.onSurface,
        ),
      ),
    );
  }
}
