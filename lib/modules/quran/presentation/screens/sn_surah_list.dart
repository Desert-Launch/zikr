import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_surah_list.dart';
import 'package:quran/modules/quran/presentation/cubits/s_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart';
import 'package:quran/modules/quran/presentation/widgets/w_juz_card.dart';
import 'package:quran/modules/quran/presentation/widgets/w_search_hit_tile.dart';
import 'package:quran/modules/quran/presentation/widgets/w_page_card.dart';
import 'package:quran/modules/quran/presentation/widgets/w_quran_header.dart';
import 'package:quran/modules/quran/presentation/widgets/w_quran_index_mode_bar.dart';
import 'package:quran/modules/quran/presentation/widgets/w_quran_summary_cards.dart';
import 'package:quran/modules/quran/presentation/widgets/w_surah_card.dart';
import 'package:quran/modules/quran/presentation/widgets/w_surah_filter_bar.dart';

class SNSurahList extends StatefulWidget {
  const SNSurahList({super.key});

  @override
  State<SNSurahList> createState() => _SNSurahListState();
}

class _SNSurahListState extends State<SNSurahList> {
  static const _green = Color(0xFF007A58);
  static const _gold = Color(0xFFD6A72C);
  static const _canvas = Color(0xFFF8F7F4);

  late final CBSurahList _cubit = Modular.get<CBSurahList>()..loadInitial();
  // Reused ayah full-text search, so one box searches both surahs and verses.
  late final CBQuranSearch _searchCubit = Modular.get<CBQuranSearch>();

  /// Fans the search box out to both the surah-name filter and the ayah search.
  void _onQueryChanged(String q) {
    _cubit.setQuery(q);
    _searchCubit.setQuery(q);
  }

  @override
  void dispose() {
    _searchCubit.close();
    super.dispose();
  }

  void _goBack() {
    if (Modular.to.canPop()) {
      Modular.to.pop();
    } else {
      Modular.to.navigate(RoutesNames.homeBase);
    }
  }

  void _openPage(int page) =>
      Modular.to.pushNamed(QuranRoutes.readerFromPage(page));

  /// The body list, swapped by the active index mode (surahs / juz / pages).
  Widget _indexSliver(SSurahList state) {
    switch (state.mode) {
      case QuranIndexMode.surah:
        return _surahSliver(state);
      case QuranIndexMode.juz:
        return SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 28.h),
          sliver: SliverList.separated(
            itemCount: state.juzIndex.length,
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
            itemBuilder: (_, index) {
              final juz = state.juzIndex[index];
              return WJuzCard(
                entry: juz,
                green: _green,
                gold: _gold,
                onOpenPage: _openPage,
              );
            },
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
                green: _green,
                onTap: () => _openPage(entry.page),
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
            green: _green,
            gold: _gold,
            onTap: () => _openPage(surah.pageStart),
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
                color: _green,
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _searchCubit),
      ],
      child: PopScope(
        canPop: Modular.to.canPop(),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Modular.to.navigate(RoutesNames.homeBase);
        },
        child: WSharedScaffold(
          backgroundColor: _canvas,
          withSafeArea: false,
          padding: EdgeInsets.zero,
          body: BlocBuilder<CBSurahList, SSurahList>(
            builder: (context, state) {
              // Nested so verse results refresh as the ayah search resolves.
              return BlocBuilder<CBQuranSearch, SQuranSearch>(
                builder: (context, search) {
                  final searching =
                      state.mode == QuranIndexMode.surah &&
                      state.query.trim().length >= 2;
                  final ayahNoResults =
                      search.status == LoadStatus.success &&
                      search.results.isEmpty;
                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: WQuranHeader(
                          cubit: _cubit,
                          onBack: _goBack,
                          onQueryChanged: _onQueryChanged,
                          onSettings: () =>
                              Modular.to.pushNamed(QuranRoutes.fullSettings()),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: WQuranIndexModeBar(
                          cubit: _cubit,
                          state: state,
                          green: _green,
                        ),
                      ),
                      if (state.mode == QuranIndexMode.surah)
                        SliverToBoxAdapter(
                          child: WSurahFilterBar(
                            cubit: _cubit,
                            state: state,
                            green: _green,
                          ),
                        ),
                      if (state.status == LoadStatus.loading &&
                          state.all.isEmpty)
                        const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (state.status == LoadStatus.error)
                        SliverFillRemaining(
                          child: Center(
                            child: Text(state.error ?? 'common_error'.tr()),
                          ),
                        )
                      else if (state.mode == QuranIndexMode.surah) ...[
                        SliverToBoxAdapter(
                          child: WQuranSummaryCards(
                            surahs: state.all.length,
                            ayat: state.all.fold(
                              0,
                              (sum, surah) => sum + surah.totalAyah,
                            ),
                            bookmarks: state.bookmarkCount,
                            green: _green,
                            gold: _gold,
                            onBookmarks: () => Modular.to.pushNamed(
                              QuranRoutes.fullBookmarks(),
                            ),
                          ),
                        ),
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
                              child: Center(
                                child: Text('search_no_results'.tr()),
                              ),
                            ),
                          ),
                      ] else ...[
                        SliverToBoxAdapter(
                          child: WQuranSummaryCards(
                            surahs: state.all.length,
                            ayat: state.all.fold(
                              0,
                              (sum, surah) => sum + surah.totalAyah,
                            ),
                            bookmarks: state.bookmarkCount,
                            green: _green,
                            gold: _gold,
                            onBookmarks: () => Modular.to.pushNamed(
                              QuranRoutes.fullBookmarks(),
                            ),
                          ),
                        ),
                        _indexSliver(state),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
