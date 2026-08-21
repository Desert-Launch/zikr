import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/utils/helper/nav_helper.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_quran_search.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_surah_list.dart';
import 'package:quran/modules/quran/presentation/widgets/w_quran_header.dart';
import 'package:quran/modules/quran/presentation/widgets/w_quran_index_content.dart';

/// The standalone Quran index screen. The index body itself lives in
/// [WQuranIndexContent], which the reader's index popup renders too — this
/// screen only adds the green header above it.
class SNSurahList extends StatefulWidget {
  const SNSurahList({super.key});

  @override
  State<SNSurahList> createState() => _SNSurahListState();
}

class _SNSurahListState extends State<SNSurahList> {
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

  void _goBack() => NavHelper.back();

  void _openPage(int page) =>
      Modular.to.pushNamed(QuranRoutes.readerFromPage(page));

  @override
  Widget build(BuildContext context) {
    return WSharedScaffold(
      backgroundColor: _canvas,
      withSafeArea: false,
      padding: EdgeInsets.zero,
      body: WQuranIndexContent(
        cubit: _cubit,
        searchCubit: _searchCubit,
        onOpenPage: _openPage,
        onBookmarks: () => Modular.to.pushNamed(QuranRoutes.fullBookmarks()),
        leadingSlivers: [
          SliverToBoxAdapter(
            child: WQuranHeader(
              cubit: _cubit,
              onBack: _goBack,
              onQueryChanged: _onQueryChanged,
              onSettings: () =>
                  Modular.to.pushNamed(QuranRoutes.fullSettings()),
            ),
          ),
        ],
      ),
    );
  }
}
