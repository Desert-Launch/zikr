import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;
import 'package:quran/modules/quran/presentation/widgets/w_ayah_action_sheet.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mini_player.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_v4_page.dart';
import 'package:quran/modules/quran/presentation/widgets/w_reader_bottom_bar.dart';
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
    _pageController = PageController(initialPage: _resolvedStart - 1, viewportFraction: 1);
    _resolveInitial();
  }

  Future<void> _resolveInitial() async {
    int target = widget.initialPage ?? 1;
    final initialAyah = widget.initialAyah;
    if (initialAyah != null) {
      target = await Modular.get<DSLocalQuran>().pageOfAyah(initialAyah.surah, initialAyah.ayah);
      if (mounted) {
        _pageController.jumpToPage(target - 1);
      }
    }
    _cubit.openPage(target);
    if (initialAyah != null) {
      _cubit.highlightAyah(ParamAyahRef(surah: initialAyah.surah, ayah: initialAyah.ayah));
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

  /// Jumps the open reader to [page] — used by the index popup and the
  /// bookmarks sheet, neither of which pushes a new reader route.
  void _jumpToPage(int page) {
    if (page < 1 || page > 604) return;
    if (_pageController.hasClients) _pageController.jumpToPage(page - 1);
    _cubit.openPage(page);
  }

  /// Resolves an ayah to its page, jumps there and highlights the verse.
  Future<void> _jumpToAyah(ParamAyahRef ref) async {
    final page = await Modular.get<DSLocalQuran>().pageOfAyah(ref.surah, ref.ayah);
    if (!mounted) return;
    _jumpToPage(page);
    _cubit.highlightAyah(ref);
  }

  Future<void> _scrollToPlayingPage(ParamAyahRef ref) async {
    final page = await Modular.get<DSLocalQuran>().pageOfAyah(ref.surah, ref.ayah);
    if (!mounted) return;
    if (_pageController.hasClients && _pageController.page?.round() != page - 1) {
      _pageController.animateToPage(page - 1, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WSharedScaffold(
        backgroundColor: readerBackground(_cubit.state.theme),
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
                  selector: (s) => readerBackground(s.theme),
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
                    // NO `reverse`: a horizontal PageView already follows the
                    // ambient direction, so under RTL page 1 sits on the right
                    // and swiping left advances. `reverse: true` was needed
                    // only while the app was pinned LTR — keeping it now
                    // double-flips the paging.
                    itemCount: 604,
                    // Builds the immediate neighbours ahead of the swipe; the
                    // pages further out in the ±3 window are already parsed in
                    // the cubit, so they mount instantly when reached.
                    allowImplicitScrolling: true,
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
                    WReaderTopBar(onOpenPage: _jumpToPage),
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
                          (a.selectedAyah == null) != (b.selectedAyah == null) || a.chromeVisible != b.chromeVisible,
                      builder: (_, s) {
                        final showMini = s.chromeVisible && s.selectedAyah == null;
                        return showMini ? const WMiniPlayer() : const SizedBox.shrink();
                      },
                    ),
                    // Bottom chrome — rides the same show/hide tap as the top
                    // bar and carries the in-reader bookmarks shortcut.
                    WReaderBottomBar(onOpenAyah: _jumpToAyah),
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

/// One slot in the reader's [PageView].
///
/// Renders straight from [SMushafReader.pages] — the cubit keeps a 7-page
/// window (current ±3) warm, so a page swiped into view is already parsed and
/// paints without a spinner.
///
/// Kept alive (not disposed) for exactly as long as it stays inside that
/// window: `wantKeepAlive` flips to false the moment the page falls outside
/// ±[CBMushafReader.preloadRadius], which is what bounds memory — the built
/// subtree is torn down in step with the cubit evicting the layout.
class _PageLoader extends StatefulWidget {
  const _PageLoader({required this.pageNumber});
  final int pageNumber;

  @override
  State<_PageLoader> createState() => _PageLoaderState();
}

class _PageLoaderState extends State<_PageLoader> with AutomaticKeepAliveClientMixin {
  bool _keepAlive = false;

  @override
  bool get wantKeepAlive => _keepAlive;

  void _syncKeepAlive(int currentPage) {
    final next = (widget.pageNumber - currentPage).abs() <= CBMushafReader.preloadRadius;
    if (next == _keepAlive) return;
    _keepAlive = next;
    // `updateKeepAlive` dispatches a KeepAliveNotification, which makes the
    // enclosing AutomaticKeepAlive rebuild — illegal during a build, so defer
    // it to the end of the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) updateKeepAlive();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<CBMushafReader, SMushafReader>(
      buildWhen: (a, b) =>
          a.currentPage != b.currentPage ||
          a.status != b.status ||
          a.pages[widget.pageNumber] != b.pages[widget.pageNumber],
      builder: (context, state) {
        _syncKeepAlive(state.currentPage);
        final layout = state.pages[widget.pageNumber];
        if (layout != null) return WMushafV4Page(layout: layout);
        final isCurrent = state.currentPage == widget.pageNumber;
        if (isCurrent && state.status == LoadStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        // Outside the warm window (or still resolving) — nothing to paint yet.
        return const SizedBox.shrink();
      },
    );
  }
}
