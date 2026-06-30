import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_surah_list.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart';
import 'package:quran/modules/quran/presentation/widgets/w_surah_filter_button.dart';

/// Top-level selector for how the index is browsed: surahs, ajzaa', or pages.
class WQuranIndexModeBar extends StatelessWidget {
  const WQuranIndexModeBar({
    super.key,
    required this.cubit,
    required this.state,
    required this.green,
  });

  final CBSurahList cubit;
  final SSurahList state;
  final Color green;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 9.h, 16.w, 4.h),
      color: Colors.white,
      child: Row(
        children: [
          WSurahFilterButton(
            label: 'surah_list_title'.tr(),
            active: state.mode == QuranIndexMode.surah,
            green: green,
            onTap: () => cubit.setMode(QuranIndexMode.surah),
          ),
          SizedBox(width: 7.w),
          WSurahFilterButton(
            label: 'surah_list_juz'.tr(),
            active: state.mode == QuranIndexMode.juz,
            green: green,
            onTap: () => cubit.setMode(QuranIndexMode.juz),
          ),
          SizedBox(width: 7.w),
          WSurahFilterButton(
            label: 'surah_list_pages'.tr(),
            active: state.mode == QuranIndexMode.page,
            green: green,
            onTap: () => cubit.setMode(QuranIndexMode.page),
          ),
        ],
      ),
    );
  }
}
