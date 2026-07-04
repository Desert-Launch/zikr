import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_bookmark.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/widgets/w_bookmark_color_picker.dart';
import 'package:quran/modules/quran/presentation/widgets/w_full_player.dart';
import 'package:quran/modules/quran/presentation/widgets/w_player_bar.dart';
import 'package:share_plus/share_plus.dart';

class WAyahActionSheet extends StatelessWidget {
  const WAyahActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      CBMushafReader,
      SMushafReader,
      ({ParamAyahRef? selected, bool chromeVisible})
    >(
      selector: (s) =>
          (selected: s.selectedAyah, chromeVisible: s.chromeVisible),
      builder: (context, state) {
        final selected = state.selected;
        final visible = selected != null && state.chromeVisible;
        return AnimatedSlide(
          offset: Offset(0, visible ? 0 : 1),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
                child: Material(
                  color: context.brand.surface,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16.r),
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    child: selected == null
                        ? const SizedBox.shrink()
                        : _SheetBody(ref: selected),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.ref});
  final ParamAyahRef ref;

  @override
  Widget build(BuildContext context) {
    final cubit = BlocProvider.of<CBMushafReader>(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: AppColorsLight.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 15.r,
                    color: AppColorsLight.primary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'سورة ${ref.surah} · آية ${ref.ayah}',
                    style: TextStyle(
                      color: AppColorsLight.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Closes the sheet only; playback keeps going and the mini player
            // takes over. Stop from the mini player to end playback.
            InkWell(
              onTap: cubit.clearSelection,
              borderRadius: BorderRadius.circular(20.r),
              child: Padding(
                padding: EdgeInsets.all(6.r),
                child: Icon(
                  Icons.close_rounded,
                  size: 20.r,
                  color: context.brand.muted,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            _Action(
              icon: Icons.play_arrow_rounded,
              label: 'reader_play'.tr(),
              // Keep the sheet open so the merged player bar below stays visible.
              onTap: (_) => Modular.get<CBAudioPlayer>().playFrom(ref),
            ),
            _Action(
              icon: Icons.menu_book_outlined,
              label: 'tafsir_action'.tr(),
              onTap: _openTafsir,
            ),
            _Action(
              icon: Icons.bookmark_add_outlined,
              label: 'reader_bookmark'.tr(),
              onTap: _bookmark,
            ),
            _Action(
              icon: Icons.copy_outlined,
              label: 'reader_copy'.tr(),
              onTap: _copy,
            ),
            _Action(
              icon: Icons.share_outlined,
              label: 'reader_share'.tr(),
              onTap: _share,
            ),
          ],
        ),
        // Merged playback bar: appears at the bottom of the sheet while audio
        // is active (e.g. after tapping play above).
        BlocBuilder<CBAudioPlayer, SAudioPlayer>(
          bloc: Modular.get<CBAudioPlayer>(),
          builder: (context, audio) {
            final active =
                audio.currentAyah != null && audio.status != PlayerStatus.idle;
            if (!active) return const SizedBox.shrink();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12.h),
                // Tap the bar to expand into the full player (speed, repeat,
                // range, …) — same affordance as the floating mini player.
                Material(
                  color: context.brand.surfaceMuted,
                  borderRadius: BorderRadius.circular(14.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () => WFullPlayer.show(context),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      child: WPlayerBar(
                        state: audio,
                        cubit: Modular.get<CBAudioPlayer>(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Readable Arabic text of the ayah for copy/share. The rendered page uses
  /// QPC-V4 glyph fonts (PUA codepoints, not readable), so the plain text is
  /// pulled from the bundled Uthmani ayah index instead.
  Future<String> _plainText() async {
    try {
      final text = await Modular.get<DSLocalQuran>().fullAyahText(ref);
      if (text.isNotEmpty) return text;
    } catch (_) {
      // Fall through to the reference label.
    }
    return '${ref.surah}:${ref.ayah}';
  }

  void _openTafsir(BuildContext context) {
    BlocProvider.of<CBMushafReader>(context).clearSelection();
    Modular.to.pushNamed(QuranRoutes.tafsirForAyah(ref.surah, ref.ayah));
  }

  Future<void> _bookmark(BuildContext context) async {
    // Let the user pick a colour first; dismissing the picker cancels the save.
    final colorHex = await showBookmarkColorPicker(context);
    if (colorHex == null || !context.mounted) return;
    final uc = Modular.get<UCSaveBookmark>();
    final result = await uc(ref: ref, colorHex: colorHex);
    if (!context.mounted) return;
    final msg = result.fold(
      (l) => 'common_error'.tr(),
      (r) => 'bookmark_saved'.tr(),
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    BlocProvider.of<CBMushafReader>(context).clearSelection();
  }

  Future<void> _copy(BuildContext context) async {
    final text = await _plainText();
    await Clipboard.setData(
      ClipboardData(text: '$text\n(${ref.surah}:${ref.ayah})'),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('reader_copy'.tr())));
    BlocProvider.of<CBMushafReader>(context).clearSelection();
  }

  Future<void> _share(BuildContext context) async {
    final text = await _plainText();
    if (!context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final screenSize = MediaQuery.sizeOf(context);
    final origin =
        box != null && box.hasSize && box.size.width > 0 && box.size.height > 0
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.fromLTWH(screenSize.width / 2, screenSize.height / 2, 1, 1);
    await Share.share(
      '$text\n— سورة ${ref.surah}، آية ${ref.ayah}',
      sharePositionOrigin: origin,
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final ValueChanged<BuildContext> onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(context);
        },
        borderRadius: BorderRadius.circular(14.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46.r,
                height: 46.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColorsLight.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColorsLight.primary, size: 24.r),
              ),
              SizedBox(height: 7.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: context.brand.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
