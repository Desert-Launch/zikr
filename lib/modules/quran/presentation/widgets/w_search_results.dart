import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_empty_state.dart';
import 'package:quran/modules/quran/data/models/m_surah.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/usecases/uc_search_quran.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/s_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;
import 'package:quran/modules/quran/presentation/widgets/mushaf_labels.dart';
import 'package:quran/modules/quran/presentation/widgets/w_number_search_results.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_hit_tile.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_meta_row.dart';
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
        if (!state.isNumeric && state.query.trim().isEmpty) {
          return _Message(
            icon: Icons.search_rounded,
            title: 'search_start_typing'.tr(),
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
        if (state.results.isEmpty && state.surahs.isEmpty) {
          return const _NoResults();
        }

        final rows = _rows(context, state);
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 24.h),
          itemCount: rows.length,
          itemBuilder: (_, i) => rows[i],
        );
      },
    );
  }

  /// The result list, top to bottom: the surahs whose name matched — there from
  /// the first letter typed — then the verses whose text did.
  List<Widget> _rows(BuildContext context, SQuranSearch state) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    String counted(int n) => 'search_results_count'
        .tr()
        .replaceFirst('{{count}}', isRtl ? arabicDigits(n) : '$n');

    return [
      if (state.surahs.isNotEmpty) ...[
        WSearchSectionHeader(
          title: 'search_section_surahs'.tr(),
          count: counted(state.surahs.length),
        ),
        for (final surah in state.surahs)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: WSearchMetaRow(
              icon: Icons.auto_stories_outlined,
              leadingBadge: isRtl ? arabicDigits(surah.number) : '${surah.number}',
              title: surah.arabic.isNotEmpty ? surah.arabic : surah.name,
              subtitle: isRtl ? surah.name : surah.arabic,
              page: surah.pageStart > 0 ? surah.pageStart : null,
              onTap: () => _openSurah(surah),
            ),
          ),
      ],
      if (state.results.isNotEmpty) ...[
        WSearchSectionHeader(
          title: 'search_section_ayat'.tr(),
          count: counted(state.results.length),
        ),
        for (final hit in state.results)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: WSearchHitTile(
              hit: hit,
              query: state.query.trim(),
              onTap: onHitTap == null ? null : () => onHitTap?.call(hit),
            ),
          ),
      ],
    ];
  }

  /// Opens [surah] at its first ayah — inside the reader already showing when
  /// this list lives in it, as a fresh reader otherwise.
  void _openSurah(MSurah surah) {
    final ref = ParamAyahRef(surah: surah.number, ayah: 1);
    final jump = onJump;
    if (jump != null) {
      jump(ref, surah.pageStart);
      return;
    }
    Modular.to.pushNamed(QuranRoutes.readerFromAyah(ref.surah, ref.ayah));
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
