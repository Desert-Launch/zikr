import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/widgets/w_empty_state.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/usecases/uc_search_quran.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/s_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;
import 'package:quran/modules/quran/presentation/widgets/mushaf_labels.dart';
import 'package:quran/modules/quran/presentation/widgets/w_number_search_results.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_hit_tile.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_section_header.dart';

class WSearchResults extends StatelessWidget {
  const WSearchResults({super.key, this.onHitTap, this.onJump});

  /// When set, tapping a result invokes this instead of pushing a new reader.
  final void Function(SearchHit hit)? onHitTap;

  /// Same, for the rows of a numeric result — they carry a page as well as an
  /// ayah, so the reader can jump straight to it.
  final void Function(ParamAyahRef? ref, int page)? onJump;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBQuranSearch, SQuranSearch>(
      builder: (context, state) {
        final numbers = state.numbers;
        if (numbers != null && state.status == LoadStatus.success) {
          if (numbers.isEmpty) return const _NoResults();
          return WNumberSearchResults(numbers: numbers, onJump: onJump);
        }
        if (!state.isNumeric && state.query.trim().length < 2) {
          return _Message(
            icon: Icons.search_rounded,
            title: 'search_min_chars'.tr(),
          );
        }
        if (state.status == LoadStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == LoadStatus.error) {
          return _Message(
            icon: Icons.error_outline_rounded,
            title: state.error ?? 'common_error'.tr(),
          );
        }
        if (state.results.isEmpty) return const _NoResults();

        final isRtl = Directionality.of(context) == TextDirection.rtl;
        final count = state.results.length;
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 24.h),
          // One extra leading row: the section header carrying the hit count.
          itemCount: count + 1,
          separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 0 : 10.h),
          itemBuilder: (_, i) {
            if (i == 0) {
              return WSearchSectionHeader(
                title: 'search_section_ayat'.tr(),
                count: 'search_results_count'.tr().replaceFirst(
                      '{{count}}',
                      isRtl ? arabicDigits(count) : '$count',
                    ),
              );
            }
            final hit = state.results[i - 1];
            final cb = onHitTap;
            return WSearchHitTile(
              hit: hit,
              query: state.query.trim(),
              onTap: cb == null ? null : () => cb(hit),
            );
          },
        );
      },
    );
  }
}

/// Nothing matched — the one wording every empty search result uses.
class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return _Message(
      icon: Icons.search_off_rounded,
      title: 'search_no_results'.tr(),
    );
  }
}

/// A centred illustration + line, for the idle, empty and error states alike so
/// the panel never jumps between three different layouts.
class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: WEmptyState(
          icon: icon,
          title: title,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }
}
