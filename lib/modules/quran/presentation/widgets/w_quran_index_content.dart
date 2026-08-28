import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_surah_list.dart';
import 'package:quran/modules/quran/presentation/cubits/s_quran_search.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart';
import 'package:quran/modules/quran/presentation/widgets/w_juz_card.dart';
import 'package:quran/modules/quran/presentation/widgets/w_page_card.dart';
import 'package:quran/modules/quran/presentation/widgets/w_quran_index_mode_bar.dart';
import 'package:quran/modules/quran/presentation/widgets/w_quran_summary_cards.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_results.dart';
import 'package:quran/modules/quran/presentation/widgets/w_surah_card.dart';
import 'package:quran/modules/quran/presentation/widgets/w_surah_filter_bar.dart';

/// The Quran index body — mode tabs (surahs / juz' / pages), the surah filter
/// row and the browsable list for the active mode.
///
/// A non-empty query replaces the whole body with [WSearchResults], the same
/// list the reader's search panel shows: surahs, verses, and — for a number —
/// the page, surah and arba' it names. So one box searches the mushaf the same
/// way wherever it is typed in.
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
    this.onOpenAyah,
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

  /// Where a search result goes. Left null the results push a fresh reader —
  /// which is what the standalone index screen wants; the reader's index popup
  /// passes a handler that closes itself and jumps in place instead.
  final void Function(ParamAyahRef? ref, int page)? onOpenAyah;

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
    // Searching takes over the whole body: the index bars and cards belong to
    // browsing, and the results list is the reader's, verbatim.
    if (search.query.trim().isNotEmpty) {
      final open = onOpenAyah;
      return [
        SliverFillRemaining(
          hasScrollBody: true,
          child: WSearchResults(
            onHitTap: open == null ? null : (hit) => open(hit.ref, hit.page),
            onJump: open,
          ),
        ),
      ];
    }

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

  /// The surah index as a sliver list, under the active filters.
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
}
