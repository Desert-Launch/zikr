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

/// Reader chrome: an app bar that slides down from the top of the Mushaf
/// screen when [SMushafReader.chromeVisible] is on. Carries the back button
/// plus the current surah name, juz' and page.
class WReaderTopBar extends StatelessWidget {
  const WReaderTopBar({super.key});

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
              child: _Bar(vm: vm),
            ),
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.vm});
  final _TopBarVM vm;

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
          child: SizedBox(
            height: 62.h,
            child: Row(
              children: [
                BackButton(
                  color: Colors.white,
                  onPressed: () => Modular.to.pop(),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vm.surahName.isEmpty ? '—' : vm.surahName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'الجزء ${vm.juz}  •  صفحة ${vm.page}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'common_search'.tr(),
                  onPressed: () =>
                      BlocProvider.of<CBMushafReader>(context).toggleSearch(),
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                ),
                IconButton(
                  tooltip: 'فهرس القرآن',
                  onPressed: () =>
                      Modular.to.navigate(QuranRoutes.fullSurahList()),
                  icon: const Icon(
                    Icons.format_list_bulleted_rounded,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  tooltip: 'quran_settings_title'.tr(),
                  onPressed: () =>
                      Modular.to.pushNamed(QuranRoutes.fullSettings()),
                  icon: const Icon(Icons.settings_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
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
