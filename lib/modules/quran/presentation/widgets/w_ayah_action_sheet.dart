import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_bookmark.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:share_plus/share_plus.dart';

class WAyahActionSheet extends StatelessWidget {
  const WAyahActionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CBMushafReader, SMushafReader, ParamAyahRef?>(
      selector: (s) => s.selectedAyah,
      builder: (context, selected) {
        final visible = selected != null;
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
                  color: Colors.white,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16.r),
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
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
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.brandPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '${ref.surah}:${ref.ayah}',
                style: TextStyle(
                  color: AppColors.brandPurple,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.sp,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: cubit.clearSelection,
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Action(
              icon: Icons.play_arrow_rounded,
              label: 'reader_play'.tr(),
              onTap: () {
                Modular.get<CBAudioPlayer>().playFrom(ref);
                BlocProvider.of<CBMushafReader>(context).clearSelection();
              },
            ),
            _Action(
              icon: Icons.repeat_rounded,
              label: 'reader_repeat'.tr(),
              onTap: () {
                Modular.get<CBAudioPlayer>().repeatSingle(ref);
                BlocProvider.of<CBMushafReader>(context).clearSelection();
              },
            ),
            _Action(
              icon: Icons.bookmark_add_outlined,
              label: 'reader_bookmark'.tr(),
              onTap: () => _bookmark(context),
            ),
            _Action(
              icon: Icons.copy_outlined,
              label: 'reader_copy'.tr(),
              onTap: () => _copy(context),
            ),
            _Action(
              icon: Icons.share_outlined,
              label: 'reader_share'.tr(),
              onTap: () => _share(context),
            ),
          ],
        ),
      ],
    );
  }

  String _plainText(BuildContext context) {
    final layout = BlocProvider.of<CBMushafReader>(context).state.layout;
    if (layout == null) return '${ref.surah}:${ref.ayah}';
    for (final line in layout.lines) {
      if (line.verseRange != null && line.verseRange!.contains(ref.key)) {
        return line.text;
      }
    }
    return '${ref.surah}:${ref.ayah}';
  }

  Future<void> _bookmark(BuildContext context) async {
    final uc = Modular.get<UCSaveBookmark>();
    final result = await uc(ref: ref);
    if (!context.mounted) return;
    final msg = result.fold(
      (l) => 'common_error'.tr(),
      (r) => 'reader_bookmark'.tr(),
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    BlocProvider.of<CBMushafReader>(context).clearSelection();
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: '${_plainText(context)}\n(${ref.surah}:${ref.ayah})'));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('reader_copy'.tr())));
    BlocProvider.of<CBMushafReader>(context).clearSelection();
  }

  Future<void> _share(BuildContext context) async {
    final text = _plainText(context);
    await Share.share('$text\n— سورة ${ref.surah}، آية ${ref.ayah}');
  }

}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.brandPurple, size: 26.r),
            SizedBox(height: 4.h),
            Text(label, style: TextStyle(fontSize: 11.sp)),
          ],
        ),
      ),
    );
  }
}

