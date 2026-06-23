import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus;
import 'package:quran/modules/quran/presentation/widgets/w_ayah_action_sheet.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mini_player.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_page.dart';
import 'package:quran/modules/quran/presentation/widgets/w_reader_search_panel.dart';
import 'package:quran/modules/quran/presentation/widgets/w_reader_top_bar.dart';

class SNMushafReader extends StatefulWidget {
  const SNMushafReader({super.key, this.initialPage, this.initialAyah});

  final int? initialPage;
  final ({int surah, int ayah})? initialAyah;

  @override
  State<SNMushafReader> createState() => _SNMushafReaderState();
}

class _SNMushafReaderState extends State<SNMushafReader> {
  late final CBMushafReader _cubit = Modular.get<CBMushafReader>();
  late final PageController _pageController;
  int _resolvedStart = 1;

  @override
  void initState() {
    super.initState();
    _resolvedStart = widget.initialPage ?? 1;
    _pageController = PageController(
      initialPage: _resolvedStart - 1,
      viewportFraction: 1,
    );
    _resolveInitial();
  }

  Future<void> _resolveInitial() async {
    int target = widget.initialPage ?? 1;
    final initialAyah = widget.initialAyah;
    if (initialAyah != null) {
      target = await Modular.get<DSLocalQuran>().pageOfAyah(
        initialAyah.surah,
        initialAyah.ayah,
      );
      if (mounted) {
        _pageController.jumpToPage(target - 1);
      }
    }
    _cubit.openPage(target);
    if (initialAyah != null) {
      _cubit.highlightAyah(
        ParamAyahRef(surah: initialAyah.surah, ayah: initialAyah.ayah),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Jumps the open reader to a search hit instead of pushing a new screen:
  /// closes the panel, lands on the hit's page and highlights the verse.
  void _openSearchHit(ParamAyahRef ref, int page) {
    _cubit.closeSearch();
    if (_pageController.hasClients) {
      _pageController.jumpToPage(page - 1);
    }
    _cubit.openPage(page);
    _cubit.highlightAyah(ref);
  }

  Future<void> _scrollToPlayingPage(ParamAyahRef ref) async {
    final page = await Modular.get<DSLocalQuran>().pageOfAyah(
      ref.surah,
      ref.ayah,
    );
    if (!mounted) return;
    if (_pageController.hasClients &&
        _pageController.page?.round() != page - 1) {
      _pageController.animateToPage(
        page - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WSharedScaffold(
        backgroundColor: readerBackground(
          _cubit.state.theme,
          colored: _cubit.state.fontMode.isColored,
        ),
        padding: EdgeInsets.zero,
        withSafeArea: false,
        body: BlocListener<CBAudioPlayer, SAudioPlayer>(
          bloc: Modular.get<CBAudioPlayer>(),
          listenWhen: (a, b) => a.currentAyah?.key != b.currentAyah?.key,
          listener: (context, audio) {
            final ayah = audio.currentAyah;
            if (ayah != null) _scrollToPlayingPage(ayah);
          },
          child: Stack(
            children: [
              // Themed backdrop behind everything (incl. the status-bar and
              // bottom insets the SafeArea leaves) so the whole screen — not
              // just the page surface — recolours with the reading theme.
              Positioned.fill(
                child: BlocSelector<CBMushafReader, SMushafReader, Color>(
                  selector: (s) =>
                      readerBackground(s.theme, colored: s.fontMode.isColored),
                  builder: (_, bg) => ColoredBox(color: bg),
                ),
              ),
              // Tapping empty space on the page toggles the reader chrome
              // (top app bar). Word taps are handled by the page's own
              // gesture recognizers and never reach this detector.
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _cubit.toggleChrome,
                child: SafeArea(
                  child: PageView.builder(
                    controller: _pageController,
                    reverse: true, // RTL — page 1 on the right
                    itemCount: 604,
                    onPageChanged: (i) => _cubit.openPage(i + 1),
                    itemBuilder: (context, i) {
                      final pageNumber = i + 1;
                      return _PageLoader(pageNumber: pageNumber);
                    },
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const WReaderTopBar(),
                    WReaderSearchPanel(onHitTap: _openSearchHit),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const WAyahActionSheet(),
                    // The action sheet hosts its own player bar. Show the
                    // standalone mini player only when there's no selection and
                    // the chrome is visible — so tapping the screen (which hides
                    // the chrome + sheet) hides the player with it.
                    BlocBuilder<CBMushafReader, SMushafReader>(
                      buildWhen: (a, b) =>
                          (a.selectedAyah == null) !=
                              (b.selectedAyah == null) ||
                          a.chromeVisible != b.chromeVisible,
                      builder: (_, s) {
                        final showMini =
                            s.chromeVisible && s.selectedAyah == null;
                        return showMini
                            ? const WMiniPlayer()
                            : const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageLoader extends StatefulWidget {
  const _PageLoader({required this.pageNumber});
  final int pageNumber;

  @override
  State<_PageLoader> createState() => _PageLoaderState();
}

class _PageLoaderState extends State<_PageLoader> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBMushafReader, SMushafReader>(
      buildWhen: (a, b) =>
          a.currentPage != b.currentPage ||
          a.status != b.status ||
          a.layout?.page != b.layout?.page,
      builder: (context, state) {
        final isCurrent = state.currentPage == widget.pageNumber;
        if (isCurrent && state.layout?.page == widget.pageNumber) {
          return WMushafPage(layout: state.layout!);
        }
        if (isCurrent && state.status == LoadStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        // For non-current pages we don't have layout cached — render nothing
        // (PageView preloads neighbour widgets but they're never visible
        // until swiped; openPage() fires when the swipe completes).
        return const SizedBox.shrink();
      },
    );
  }
}
