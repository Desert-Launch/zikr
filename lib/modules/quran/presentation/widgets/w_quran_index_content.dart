import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_surah_list.dart';
import 'package:quran/modules/quran/presentation/cubits/s_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart';
import 'package:quran/modules/quran/presentation/widgets/w_juz_card.dart';
import 'package:quran/modules/quran/presentation/widgets/w_page_card.dart';
import 'package:quran/modules/quran/presentation/widgets/w_quran_index_mode_bar.dart';
import 'package:quran/modules/quran/presentation/widgets/w_quran_summary_cards.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_hit_tile.dart';
import 'package:quran/modules/quran/presentation/widgets/w_surah_card.dart';
import 'package:quran/modules/quran/presentation/widgets/w_surah_filter_bar.dart';

/// The Quran index body — mode tabs (surahs / juz' / pages), the surah filter
/// row, the browsable list for the active mode and the ayah search results.
///
/// Single source of truth for the index: the standalone [SNSurahList] screen and
/// the reader's index popup ([WQuranIndexSheet]) both render this, differing
/// only in the [leadingSlivers] they put above it and whether the summary cards
/// are shown.
class WQuranIndexContent extends StatelessWidget {
  const WQuranIndexContent({
    super.key,
    required this.cubit,
    required this.searchCubit,
    required this.onOpenPage,
    this.leadingSlivers = const <Widget>[],
    this.showSummary = true,
    this.onBookmarks,
    this.controller,
  });

  final CBSurahList cubit;
  final CBQuranSearch searchCubit;

  /// Called with the Mushaf page to open. The screen pushes the reader; the
  /// popup closes itself first and jumps the reader already underneath it.
  final ValueChanged<int> onOpenPage;

  /// Slivers rendered above the index (the screen's green header, the popup's
  /// grab handle + search row).
  final List<Widget> leadingSlivers;

  /// Whether to show the surah/ayah/bookmark summary cards. Off in the popup,
  /// where vertical space is tight.
  final bool showSummary;
  final VoidCallback? onBookmarks;
  final ScrollController? controller;

  static const Color green = Color(0xFF007A58);
  static const Color gold = Color(0xFFD6A72C);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider.value(value: searchCubit),
      ],
      child: BlocBuilder<CBSurahList, SSurahList>(
        bloc: cubit,
        builder: (context, state) {
          // Nested so verse results refresh as the ayah search resolves.
          return BlocBuilder<CBQuranSearch, SQuranSearch>(
            bloc: searchCubit,
            builder: (context, search) {
              return CustomScrollView(
                controller: controller,
                slivers: [...leadingSlivers, ..._indexSlivers(state, search)],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _indexSlivers(SSurahList state, SQuranSearch search) {
    final searching =
        state.mode == QuranIndexMode.surah && state.query.trim().length >= 2;
    final ayahNoResults =
        search.status == LoadStatus.success && search.results.isEmpty;

    return [
      SliverToBoxAdapter(
        child: WQuranIndexModeBar(cubit: cubit, state: state, green: green),
      ),
      if (state.mode == QuranIndexMode.surah)
        SliverToBoxAdapter(
          child: WSurahFilterBar(cubit: cubit, state: state, green: green),
        ),
      if (state.status == LoadStatus.loading && state.all.isEmpty)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        )
      else if (state.status == LoadStatus.error)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(state.error ?? 'common_error'.tr())),
        )
      else ...[
        if (showSummary) _summarySliver(state),
        if (state.mode == QuranIndexMode.surah) ...[
          // Surah-name matches.
          if (state.visible.isNotEmpty) ...[
            if (searching)
              _sectionLabel(
                'surah_list_results_surahs'.tr(),
                state.visible.length,
              ),
            _surahSliver(state),
          ],
          // Ayah (verse) matches.
          if (searching) ..._ayahSlivers(search),
          // Nothing matched either index.
          if (searching && state.visible.isEmpty && ayahNoResults)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48.h),
                child: Center(child: Text('search_no_results'.tr())),
              ),
            ),
        ] else
          _modeSliver(state),
      ],
    ];
  }

  Widget _summarySliver(SSurahList state) {
    return SliverToBoxAdapter(
      child: WQuranSummaryCards(
        surahs: state.all.length,
        ayat: state.all.fold(0, (sum, surah) => sum + surah.totalAyah),
        bookmarks: state.bookmarkCount,
        green: green,
        gold: gold,
        onBookmarks: onBookmarks ?? () {},
      ),
    );
  }

  /// The body list for the non-surah modes (juz' / pages).
  Widget _modeSliver(SSurahList state) {
    switch (state.mode) {
      case QuranIndexMode.surah:
        return _surahSliver(state);
      case QuranIndexMode.juz:
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
          sliver: SliverList.separated(
            itemCount: state.juzIndex.length,
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
            itemBuilder: (_, index) => WJuzCard(
              entry: state.juzIndex[index],
              green: green,
              gold: gold,
              onOpenPage: onOpenPage,
            ),
          ),
        );
      case QuranIndexMode.page:
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
          sliver: SliverList.separated(
            itemCount: state.pageIndex.length,
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
            itemBuilder: (_, index) {
              final entry = state.pageIndex[index];
              return WPageCard(
                entry: entry,
                green: green,
                onTap: () => onOpenPage(entry.page),
              );
            },
          ),
        );
    }
  }

  /// The matching surahs as a sliver list.
  Widget _surahSliver(SSurahList state) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
      sliver: SliverList.separated(
        itemCount: state.visible.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (_, index) {
          final surah = state.visible[index];
          return WSurahCard(
            surah: surah,
            green: green,
            gold: gold,
            onTap: () => onOpenPage(surah.pageStart),
          );
        },
      ),
    );
  }

  /// A small section heading with a result count, separating surah and ayah
  /// results while a query is active.
  Widget _sectionLabel(String text, int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 2.h),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: green,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              '($count)',
              style: TextStyle(fontSize: 12.sp, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  /// The ayah (verse) full-text results, reusing the shared search hit tiles.
  List<Widget> _ayahSlivers(SQuranSearch search) {
    if (search.status == LoadStatus.loading) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }
    if (search.results.isEmpty) return const [];
    return [
      _sectionLabel('surah_list_results_ayat'.tr(), search.results.length),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
        sliver: SliverList.separated(
          itemCount: search.results.length,
          separatorBuilder: (_, __) => SizedBox(height: 8.h),
          itemBuilder: (_, i) => WSearchHitTile(
            hit: search.results[i],
            query: search.query.trim(),
          ),
        ),
      ),
    ];
  }
}
