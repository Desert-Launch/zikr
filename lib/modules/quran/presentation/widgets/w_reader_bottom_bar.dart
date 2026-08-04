import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/widgets/w_reader_bookmarks_sheet.dart';

/// Reader chrome at the bottom of the Mushaf: slides up and down with
/// [SMushafReader.chromeVisible], i.e. it appears and disappears on the same
/// screen tap that toggles the top bar.
///
/// Hosts the in-reader bookmarks shortcut — tapping it opens
/// [WReaderBookmarksSheet], and choosing a verse jumps the open reader to it.
/// Hidden while an ayah is selected, so it never stacks under the ayah action
/// sheet.
class WReaderBottomBar extends StatelessWidget {
  const WReaderBottomBar({super.key, required this.onOpenAyah});

  final ValueChanged<ParamAyahRef> onOpenAyah;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CBMushafReader, SMushafReader, bool>(
      selector: (s) => s.chromeVisible && s.selectedAyah == null,
      builder: (context, visible) {
        return IgnorePointer(
          ignoring: !visible,
          child: AnimatedSlide(
            offset: Offset(0, visible ? 0 : 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
                  child: Material(
                    color: AppColorsLight.primary,
                    elevation: 6,
                    borderRadius: BorderRadius.circular(18.r),
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'reader_bookmarks'.tr(),
                            onPressed: () => WReaderBookmarksSheet.show(
                              context,
                              onOpenAyah: onOpenAyah,
                            ),
                            visualDensity: VisualDensity.compact,
                            iconSize: 22.r,
                            icon: const Icon(
                              Icons.bookmarks_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
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
