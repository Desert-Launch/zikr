import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_surah_list.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart';
import 'package:quran/modules/quran/presentation/widgets/w_surah_filter_button.dart';

class WSurahFilterBar extends StatelessWidget {
  const WSurahFilterBar({
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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          WSurahFilterButton(
            label:
                '${state.all.where((s) => s.isMadani).length}  '
                '${'surah_list_filter_madani'.tr()}',
            active: state.filter == SurahFilter.madani,
            green: green,
            onTap: () => cubit.setFilter(SurahFilter.madani),
          ),
          SizedBox(width: 7.w),
          WSurahFilterButton(
            label:
                '${state.all.where((s) => s.isMakki).length}  '
                '${'surah_list_filter_makki'.tr()}',
            active: state.filter == SurahFilter.makki,
            green: green,
            onTap: () => cubit.setFilter(SurahFilter.makki),
          ),
          SizedBox(width: 7.w),
          WSurahFilterButton(
            label: 'common_all'.tr(),
            active: state.filter == SurahFilter.all,
            green: green,
            onTap: () => cubit.setFilter(SurahFilter.all),
          ),
        ],
      ),
    );
  }
}
