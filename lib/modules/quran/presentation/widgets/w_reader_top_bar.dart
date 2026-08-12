import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/widgets/mushaf_labels.dart';
import 'package:quran/modules/quran/presentation/widgets/w_quran_index_sheet.dart';

/// Reader chrome: an app bar that slides down from the top of the Mushaf
/// screen when [SMushafReader.chromeVisible] is on, and slides away again on
/// the cubit's auto-hide timer. Carries the back button plus the current surah
/// name, juz'/page, and the hizb with the rub' of it reached.
class WReaderTopBar extends StatelessWidget {
  const WReaderTopBar({super.key, required this.onOpenPage});

  /// Target page chosen from the index popup — the reader jumps in place.
  final ValueChanged<int> onOpenPage;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CBMushafReader, SMushafReader, _TopBarVM>(
      selector: (s) => _TopBarVM(
        visible: s.chromeVisible,
        surahName: s.surahName,
        juz: s.juz,
        page: s.currentPage,
      ),
      builder: (context, vm) {
        return IgnorePointer(
          ignoring: !vm.visible,
          child: AnimatedSlide(
            offset: Offset(0, vm.visible ? 0 : -1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: vm.visible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: _Bar(vm: vm, onOpenPage: onOpenPage),
            ),
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.vm, required this.onOpenPage});
  final _TopBarVM vm;
  final ValueChanged<int> onOpenPage;


  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColorsLight.primary,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            // Still deliberately compact — the bar floats OVER the page, so
            // every logical pixel here is one the first line of Quran text
            // loses — but sized by its content rather than pinned to a number.
            // The three-line title (surah, juz'/page, hizb) already outgrows
            // the icon buttons' own 40.h, and a fixed height that fits it here
            // would shave the descenders off the last line at a larger system
            // text scale. This costs the page a line's height only for the two
            // seconds the bar is up.
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Row(
              children: [
                BackButton(
                  color: Colors.white,
                  onPressed: () => Modular.to.pop(),
                ),
                _BarIcon(
                  tooltip: 'common_search'.tr(),
                  icon: Icons.search_rounded,
                  onPressed: () =>
                      BlocProvider.of<CBMushafReader>(context).toggleSearch(),
                ),

                Expanded(
                  child: InkWell(
                    onTap: () =>
                        WQuranIndexSheet.show(context, onOpenPage: onOpenPage),
                    // Plain Column, NOT another Expanded. Expanded is a
                    // ParentDataWidget: it only means anything as a direct
                    // child of a Flex, and this slot belongs to an InkWell.
                    // The Expanded just above already claims the Row's spare
                    // width — the inner one only threw "Incorrect use of
                    // ParentDataWidget" on every build of the reader.
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          vm.surahName.isEmpty ? '—' : vm.surahName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.amiri(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'الجزء ${vm.juz}  •  صفحة ${vm.page}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          mushafHizbLabel(vm.page),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Opens the index as a popup over the reader rather than
                // navigating away — same content, page stays behind it.
                _BarIcon(
                  tooltip: 'reader_index'.tr(),
                  icon: Icons.format_list_bulleted_rounded,
                  onPressed: () =>
                      WQuranIndexSheet.show(context, onOpenPage: onOpenPage),
                ),
                _BarIcon(
                  tooltip: 'quran_settings_title'.tr(),
                  icon: Icons.settings_rounded,
                  onPressed: () =>
                      Modular.to.pushNamed(QuranRoutes.fullSettings()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon button sized for the compact reader bar — the Material default is 48px
/// tall with 8px padding, which alone would blow the bar's height budget.
class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
      visualDensity: VisualDensity.compact,
      iconSize: 22.r,
      icon: Icon(icon, color: Colors.white),
    );
  }
}

class _TopBarVM {
  const _TopBarVM({
    required this.visible,
    required this.surahName,
    required this.juz,
    required this.page,
  });

  final bool visible;
  final String surahName;
  final int juz;
  final int page;

  @override
  bool operator ==(Object other) =>
      other is _TopBarVM &&
      other.visible == visible &&
      other.surahName == surahName &&
      other.juz == juz &&
      other.page == page;

  @override
  int get hashCode => Object.hash(visible, surahName, juz, page);
}
