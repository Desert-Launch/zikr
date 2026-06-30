import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_surah_list.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart';
import 'package:quran/modules/quran/presentation/widgets/w_juz_card.dart';
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
        if (state.visible.isEmpty) {
          return SliverFillRemaining(
            child: Center(child: Text('search_no_results'.tr())),
          );
        }
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
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
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: WQuranHeader(
                      cubit: _cubit,
                      onBack: _goBack,
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
                  if (state.status == LoadStatus.loading && state.all.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.status == LoadStatus.error)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(state.error ?? 'common_error'.tr()),
                      ),
                    )
                  else ...[
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
                        onBookmarks: () =>
                            Modular.to.pushNamed(QuranRoutes.fullBookmarks()),
                      ),
                    ),
                    _indexSliver(state),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
