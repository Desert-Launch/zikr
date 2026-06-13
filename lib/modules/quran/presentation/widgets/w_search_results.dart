import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/s_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;
import 'package:quran/modules/quran/presentation/widgets/w_search_hit_tile.dart';

class WSearchResults extends StatelessWidget {
  const WSearchResults({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBQuranSearch, SQuranSearch>(
      builder: (context, state) {
        if (state.query.trim().length < 2) {
          return Center(
            child: Text(
              'search_min_chars'.tr(),
              style: TextStyle(fontSize: 13.sp, color: context.brand.muted),
            ),
          );
        }
        if (state.status == LoadStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == LoadStatus.error) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                state.error ?? 'common_error'.tr(),
                style: TextStyle(fontSize: 13.sp, color: AppColors.semanticDanger),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (state.results.isEmpty) {
          return Center(
            child: Text(
              'search_no_results'.tr(),
              style: TextStyle(fontSize: 13.sp, color: context.brand.muted),
            ),
          );
        }
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  Text(
                    'search_results_count'
                        .tr()
                        .replaceFirst('{{count}}', '${state.results.length}'),
                    style: TextStyle(fontSize: 12.sp, color: context.brand.muted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.only(bottom: 24.h),
                itemCount: state.results.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1.h, color: context.brand.border),
                itemBuilder: (_, i) =>
                    WSearchHitTile(hit: state.results[i], query: state.query.trim()),
              ),
            ),
          ],
        );
      },
    );
  }
}
