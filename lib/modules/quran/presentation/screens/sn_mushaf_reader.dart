import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/utils/helper/orientation_helper.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_quran.dart';
import 'package:quran/modules/quran/domain/entities/e_reader_scroll_mode.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/cb_reader_settings.dart';
import 'package:quran/modules/quran/presentation/cubits/s_audio_player.dart';
import 'package:quran/modules/quran/presentation/cubits/s_mushaf_reader.dart';
import 'package:quran/modules/quran/presentation/cubits/s_reader_settings.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus;
import 'package:quran/modules/quran/presentation/widgets/w_ayah_action_sheet.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mini_player.dart';
import 'package:quran/modules/quran/presentation/widgets/w_mushaf_v4_page.dart';
import 'package:quran/modules/quran/presentation/widgets/w_pinch_font_zoom.dart';
import 'package:quran/modules/quran/presentation/widgets/w_reader_search_panel.dart';
import 'package:quran/modules/quran/presentation/widgets/w_reader_top_bar.dart';

class SNMushafReader extends StatefulWidget {
  const SNMushafReader({super.key, this.initialPage, this.initialAyah});

  final int? initialPage;
  final ({int surah, int ayah})? initialAyah;

  @override
  State<SNMushafReader> createState() => _SNMushafReaderState();
}

/// Pages in the Madani Mushaf — the item count of both scroll views.
const int _kPageCount = 604;

class _SNMushafReaderState extends State<SNMushafReader> with OrientationOverrideRoute {
  /// The mushaf reads well in landscape too, so the reader is the one screen
  /// that opts out of the app-wide portrait lock — for exactly as long as it is
  /// the screen being read. See [OrientationOverrideRoute].
  @override
  List<DeviceOrientation> get orientations => OrientationHelper.free;

  late final CBMushafReader _cubit = Modular.get<CBMushafReader>();

  /// Resolved once and provided to the subtree below, never fetched from
  /// Modular inside `build`: this route's module is disposed the moment the pop
  /// begins, while the outgoing screen still rebuilds for the length of the
  /// transition — and a `Modular.get` in that rebuild throws
  /// `BindNotFoundException`.
  late final CBAudioPlayer _audio = Modular.get<CBAudioPlayer>();

  /// Shared reader display settings — the pinch gesture reads its on/off
  /// switch from here and writes the text size back to it.
  late final CBReaderSettings _settings = Modular.get<CBReaderSettings>();

  /// Horizontal mode: one page per viewport, snapped.
  late final PageController _pageController;

  /// Vertical mode: a free ScrollController over the same 604 pages, laid out
  /// at their natural heights so nothing snaps and nothing stops at a page
  /// boundary.
  final ScrollController _scrollController = ScrollController();

  /// Page pinned to scroll offset 0 in vertical mode.
  ///
  /// Natural-height pages have no offset arithmetic to jump by, so the list is
  /// split into two slivers around [_verticalCenterKey]: pages after the anchor
  /// grow forward from offset 0, pages before it grow backward into negative
  /// offsets. Jumping to a page is therefore "re-anchor, then `jumpTo(0)`" —
  /// exact at any text size, and it needs no index-aware list package.
  int _anchorPage = 1;
  final Key _verticalCenterKey = const ValueKey('mushaf-vertical-center');

  /// The vertical viewport, for resolving which page sits under the reader's
  /// eye (see [_probes]).
  final GlobalKey _verticalViewportKey = GlobalKey();

  /// Contexts of the pages currently mounted in the vertical list — a handful
  /// at most. Their render boxes are what turn a scroll offset back into a page
  /// number now that pages are no longer a uniform height.
  final Map<int, BuildContext> _probes = <int, BuildContext>{};

  /// Height of one screen in the vertical list — the floor every page is laid
  /// out against. 0 until the list has been laid out once.
  double _pageExtent = 0;

  /// Debounce behind [_onVerticalScroll]: the page under the reading line is
  /// recomputed every scroll frame, but *opening* it is not free — it emits new
  /// reader state, evicts and re-resolves the page window and warms fonts for
  /// five pages. Doing that at every page boundary a fling crosses is what made
  /// a fast scroll stutter and let go of the finger.
  ///
  /// Because the timer restarts on every change, a fling that crosses a page
  /// every few frames never fires it: the reader lands, the pages stop moving,
  /// and one `openPage` runs for the page actually arrived at. A slow read-scroll
  /// crosses a boundary rarely, so it fires promptly each time.
  Timer? _pageSettle;
  int? _pendingPage;

  /// When the last page open actually ran, so [_pageMaxDefer] can be enforced.
  DateTime _lastPageOpen = DateTime.fromMillisecondsSinceEpoch(0);

  /// How long the pages must hold still before the heavy page-open runs.
  static const Duration _pageSettleDelay = Duration(milliseconds: 120);

  /// Ceiling on how long the open can be deferred while the list keeps moving.
  ///
  /// A pure debounce never fires during a long fling — the timer restarts every
  /// time another page goes past — and the reader would watch blank slots the
  /// whole way down, because a page outside the cubit's window has nothing to
  /// paint. This caps it: however fast the scroll, the window is dragged along
  /// roughly three times a second, which is enough to keep pages painted and
  /// still an order of magnitude less work than opening one per boundary.
  static const Duration _pageMaxDefer = Duration(milliseconds: 350);

  /// The scroll mode the live scroll view was built for, so a change can be
  /// detected in `build` and answered with a re-seat on the current page.
  EReaderScrollMode? _builtMode;

  int _resolvedStart = 1;

  @override
  void initState() {
    super.initState();
    _resolvedStart = widget.initialPage ?? 1;
    _pageController = PageController(
      initialPage: _resolvedStart - 1,
      viewportFraction: 1,
    );
    _anchorPage = _resolvedStart;
    _scrollController.addListener(_onVerticalScroll);
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
        _seekToPage(target);
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
    _pageSettle?.cancel();
    _scrollController.removeListener(_onVerticalScroll);
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  bool get _isVertical => _cubit.state.scrollMode.isVertical;

  /// Moves whichever scroll view is live onto [page], without touching the
  /// cubit — callers that also need the page *loaded* go through [_jumpToPage].
  void _seekToPage(int page) {
    _cancelPendingPage();
    if (!_isVertical) {
      if (_pageController.hasClients) _pageController.jumpToPage(page - 1);
      return;
    }
    // Offset 0 is the top of the anchor page both before and after a re-anchor,
    // so resetting first means the list never renders a frame at a stale offset
    // against freshly re-numbered slivers.
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    if (_anchorPage == page) return;
    setState(() => _anchorPage = page);
    // Belt and braces for the case where the controller had no clients above —
    // the slivers exist by the end of this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  /// The render box of a mounted page, or null if it is off-layout — a page the
  /// sliver is keeping alive off-screen is detached from the render tree, and
  /// asking a detached box where it is throws.
  RenderBox? _probeBox(int page) {
    final box = _probes[page]?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box;
  }

  void _registerProbe(int page, BuildContext context) =>
      _probes[page] = context;
  void _unregisterProbe(int page) => _probes.remove(page);

  /// Global y of the point in the viewport that decides "the page I am reading"
  /// — a third of the way down, so a page counts as current once its top third
  /// is on screen rather than only at the halfway mark.
  double? _readingLineY() {
    final box = _verticalViewportKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset(0, box.size.height / 3)).dy;
  }

  /// Tracks the page under the reading line as the continuous list scrolls —
  /// the vertical counterpart of `PageView.onPageChanged`.
  ///
  /// Pages are natural-height now, so there is no offset arithmetic to do this
  /// with; instead the mounted pages are asked where they are. That is only ever
  /// a handful of render boxes, so it is cheap enough to run per scroll frame.
  void _onVerticalScroll() {
    if (!_isVertical) return;
    final lineY = _readingLineY();
    if (lineY == null) return;
    for (final page in _probes.keys) {
      final box = _probeBox(page);
      if (box == null) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (lineY >= top && lineY < top + box.size.height) {
        _notePageUnderReader(page);
        return;
      }
    }
  }

  /// Records the page the reader has scrolled onto and arms [_pageSettle].
  ///
  /// Nothing heavy happens here — see the field's comment for why the open is
  /// deferred rather than run inline.
  void _notePageUnderReader(int page) {
    if (page == _pendingPage || page == _cubit.state.currentPage) return;
    _pendingPage = page;
    if (DateTime.now().difference(_lastPageOpen) >= _pageMaxDefer) {
      _flushPendingPage();
      return;
    }
    _pageSettle?.cancel();
    _pageSettle = Timer(_pageSettleDelay, _flushPendingPage);
  }

  /// Opens whichever page the deferred tracker is holding. Called by the timer
  /// and again the moment the list stops moving, so settling never waits out
  /// the full delay.
  void _flushPendingPage() {
    _pageSettle?.cancel();
    _pageSettle = null;
    final page = _pendingPage;
    _pendingPage = null;
    if (page == null || !mounted) return;
    if (page == _cubit.state.currentPage) return;
    _lastPageOpen = DateTime.now();
    _cubit.openPage(page);
  }

  /// Drops a deferred page open — used by every explicit jump, which opens the
  /// page it lands on itself and must not be overwritten a moment later by
  /// wherever the list happened to be when the jump started.
  void _cancelPendingPage() {
    _pageSettle?.cancel();
    _pageSettle = null;
    _pendingPage = null;
  }

  /// Jumps the open reader to a search hit instead of pushing a new screen:
  /// closes the panel, lands on the hit's page and highlights the verse.
  void _openSearchHit(ParamAyahRef ref, int page) {
    _cubit.closeSearch();
    _seekToPage(page);
    _cubit.openPage(page);
    _cubit.highlightAyah(ref);
  }

  /// Jumps the open reader to [page] — used by the index popup and the
  /// bookmarks sheet, neither of which pushes a new reader route.
  void _jumpToPage(int page) {
    if (page < 1 || page > _kPageCount) return;
    _seekToPage(page);
    _cubit.openPage(page);
  }

  /// Resolves an ayah to its page, jumps there and highlights the verse.
  Future<void> _jumpToAyah(ParamAyahRef ref) async {
    final page = await Modular.get<DSLocalQuran>().pageOfAyah(
      ref.surah,
      ref.ayah,
    );
    if (!mounted) return;
    _jumpToPage(page);
    _cubit.highlightAyah(ref);
  }

  Future<void> _scrollToPlayingPage(ParamAyahRef ref) async {
    final page = await Modular.get<DSLocalQuran>().pageOfAyah(
      ref.surah,
      ref.ayah,
    );
    if (!mounted) return;
    const duration = Duration(milliseconds: 300);
    if (_isVertical) {
      // Already the page being read — don't fight a reader who has scrolled a
      // little way into it while the recitation runs.
      if (_cubit.state.currentPage == page) return;
      // Still mounted just off-screen: glide to it rather than re-anchoring,
      // which would be a hard cut for what is usually a one-page advance.
      final probe = _probeBox(page);
      final viewport = _verticalViewportKey.currentContext?.findRenderObject();
      if (probe != null &&
          viewport is RenderBox &&
          _scrollController.hasClients) {
        final position = _scrollController.position;
        final target =
            (position.pixels +
                    probe.localToGlobal(Offset.zero, ancestor: viewport).dy)
                .clamp(position.minScrollExtent, position.maxScrollExtent);
        _scrollController.animateTo(
          target,
          duration: duration,
          curve: Curves.easeOut,
        );
        return;
      }
      _seekToPage(page);
      return;
    }
    if (_pageController.hasClients &&
        _pageController.page?.round() != page - 1) {
      _pageController.animateToPage(
        page - 1,
        duration: duration,
        curve: Curves.easeOut,
      );
    }
  }

  /// The reader's scroll view for [mode].
  ///
  /// Switching mode swaps the whole widget, so the new one starts at its own
  /// zero — the post-frame re-seat puts it back on the page the reader was
  /// already on.
  ///
  /// [lockScroll] is set while a pinch is in progress. Handing the scroll view
  /// `NeverScrollableScrollPhysics` does more than ignore new drags: Scrollable
  /// tears its drag recognizers down and cancels the live drag, which settles a
  /// half-swiped PageView onto the nearest page instead of leaving it stranded
  /// between two while the fingers zoom.
  Widget _pagesView(EReaderScrollMode mode, {required bool lockScroll}) {
    if (mode != _builtMode) {
      _builtMode = mode;
      final page = _cubit.state.currentPage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _seekToPage(page);
      });
    }

    if (!mode.isVertical) {
      return PageView.builder(
        controller: _pageController,
        physics: lockScroll ? const NeverScrollableScrollPhysics() : null,
        // NO `reverse`: a horizontal PageView already follows the ambient
        // direction, so under RTL page 1 sits on the right and swiping left
        // advances. `reverse: true` was needed only while the app was pinned
        // LTR — keeping it now double-flips the paging.
        itemCount: _kPageCount,
        // Builds the immediate neighbours ahead of the swipe; the pages further
        // out in the ±3 window are already parsed in the cubit, so they mount
        // instantly when reached.
        allowImplicitScrolling: true,
        onPageChanged: (i) => _cubit.openPage(i + 1),
        itemBuilder: (context, i) =>
            RepaintBoundary(child: _PageLoader(pageNumber: i + 1)),
      );
    }

    // Continuous mode. Each page is laid out at its natural height — floored at
    // one screen — and carries no scroll view of its own, so a drag runs from
    // the first line of the Mushaf to the last without ever meeting an edge.
    //
    // The price is that page N no longer sits at a computable offset, which is
    // what [_anchorPage] and the two slivers below buy back.
    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = constraints.maxHeight;
        if (extent > 0 && extent != _pageExtent) {
          final page = _cubit.state.currentPage;
          _pageExtent = extent;
          // First layout, or a resize/rotation: land back on the current page
          // rather than wherever the old offset now points.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _seekToPage(page);
          });
        }
        return NotificationListener<ScrollEndNotification>(
          // The debounce behind [_notePageUnderReader] exists to keep the heavy
          // page open off a moving list; the instant the list stops there is no
          // reason to keep waiting it out.
          onNotification: (_) {
            _flushPendingPage();
            return false;
          },
          child: CustomScrollView(
            key: _verticalViewportKey,
            controller: _scrollController,
            // `null` means the platform's own physics, resolved through
            // ScrollConfiguration: iOS gets the bouncing simulation its users
            // expect (and, more to the point, iOS's momentum curve and its
            // fling-onto-a-fling chaining), Android keeps clamping. Pinning this
            // to ClampingScrollPhysics gave every iPhone reader Android's
            // deceleration and a hard stop at both ends of the Mushaf.
            physics: lockScroll ? const NeverScrollableScrollPhysics() : null,
            center: _verticalCenterKey,
            slivers: [
              // Everything before the anchor, growing backwards: index 0 is the
              // page immediately above it.
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _verticalPage(_anchorPage - 1 - i, extent),
                  childCount: _anchorPage - 1,
                ),
              ),
              SliverList(
                key: _verticalCenterKey,
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _verticalPage(_anchorPage + i, extent),
                  childCount: _kPageCount - _anchorPage + 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// One page in the continuous list.
  ///
  /// The [RepaintBoundary] is what stops a page that changed — a tap
  /// highlighting a verse, a page finally getting its font — from dragging
  /// every other mounted page into the same repaint. Pages are large, glyph-
  /// heavy layers; re-rasterising all of them at once is exactly the kind of
  /// frame a scroll cannot afford.
  Widget _verticalPage(int page, double extent) => _PageProbe(
    key: ValueKey('mushaf-page-$page'),
    pageNumber: page,
    onMount: _registerProbe,
    onUnmount: _unregisterProbe,
    child: RepaintBoundary(
      child: _PageLoader(pageNumber: page, continuousHeight: extent),
    ),
  );

  /// Whether the platform's own "go back" gesture has to be taken away while
  /// the Mushaf is open.
  ///
  /// On iOS it does. The system back gesture is a drag inwards from the leading
  /// edge, and in an RTL reader that is the leading edge of the *page* — the
  /// exact stroke that turns to the next page in horizontal mode, and one that
  /// lands squarely on the text in either mode. The route's gesture wins the
  /// arena, so the reader's swipe kept being answered by the screen sliding
  /// away instead of the page turning.
  ///
  /// `canPop: false` is what disables it: Cupertino's transition asks the route
  /// whether a pop is allowed before it will arm the recogniser at all. The
  /// reader is not made unleavable by this — the top bar's back button calls
  /// `Modular.to.pop()` directly, which PopScope does not gate.
  ///
  /// Android keeps its normal back: the hardware/gesture back there is not a
  /// horizontal drag over the page, so there is nothing to disambiguate.
  bool get _blocksSystemPop => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cubit),
        BlocProvider.value(value: _audio),
      ],
      child: PopScope(
        canPop: !_blocksSystemPop,
        child: WSharedScaffold(
          // The PopScope above suppresses the iOS edge-swipe deliberately —
          // it must not be turned into a jump to Home. The top bar's back
          // button goes through NavHelper instead.
          rootBackToHome: false,
          backgroundColor: readerBackground(_cubit.state.theme),
          padding: EdgeInsets.zero,
          withSafeArea: false,
          body: MultiBlocListener(
            listeners: [
              BlocListener<CBAudioPlayer, SAudioPlayer>(
                listenWhen: (a, b) => a.currentAyah?.key != b.currentAyah?.key,
                listener: (context, audio) {
                  final ayah = audio.currentAyah;
                  if (ayah != null) _scrollToPlayingPage(ayah);
                },
              ),
              // Verses picked in the bookmarks sheet / colour picker land here —
              // those widgets can't reach the PageController, so they raise a
              // request on the cubit and this screen performs the jump.
              BlocListener<CBMushafReader, SMushafReader>(
                listenWhen: (a, b) => a.jumpRequest != b.jumpRequest,
                listener: (context, state) {
                  final ref = state.jumpRequest;
                  if (ref == null) return;
                  _cubit.consumeJumpRequest();
                  _jumpToAyah(ref);
                },
              ),
            ],
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
                // Tapping empty space on the page clears a lit-up verse, or —
                // when nothing is selected — toggles the reader chrome (top app
                // bar). Word taps are handled by the page's own gesture
                // recognizers and never reach this detector.
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _cubit.dismissOrToggleChrome,
                  // Two-finger pinch drives the SAME text-size value the settings
                  // slider writes, committed once on release. It reads raw
                  // pointers rather than competing in the gesture arena, so two
                  // fingers always zoom — even mid-swipe — while single-finger
                  // paging, continuous scroll and word taps are untouched.
                  child:
                      BlocSelector<
                        CBReaderSettings,
                        SReaderSettings,
                        ({bool enabled, double scale})
                      >(
                        bloc: _settings,
                        selector: (s) =>
                            (enabled: s.pinchZoom, scale: s.fontScale),
                        builder: (_, zoom) {
                          // `bottom: false`, with a small clearance put back by
                          // hand. The system bottom inset is ~34pt on a
                          // gesture-bar phone, and handing all of it to the OS
                          // left a band of empty paper under the running foot
                          // taller than the foot itself. The two things the foot
                          // carries — the folio and the rub' label — sit in the
                          // page's outer CORNERS, while the home indicator is a
                          // short bar in the middle, so they never collide; the
                          // clearance is only there to keep them off the very
                          // edge of the glass. The reclaimed height goes back
                          // into the page, where the line distribution spends it
                          // on the gaps between lines.
                          Widget pages(bool lockScroll) => SafeArea(
                            bottom: false,
                            minimum: EdgeInsets.only(bottom: 24.h),
                            child:
                                BlocSelector<
                                  CBMushafReader,
                                  SMushafReader,
                                  EReaderScrollMode
                                >(
                                  selector: (s) => s.scrollMode,
                                  builder: (_, mode) =>
                                      _pagesView(mode, lockScroll: lockScroll),
                                ),
                          );
                          // Switched off: no pointer listener is installed at all,
                          // so the reader behaves exactly as it did before the
                          // feature existed rather than merely ignoring callbacks.
                          if (!zoom.enabled) return pages(false);
                          return WPinchFontZoom(
                            scale: zoom.scale,
                            minScale: CBReaderSettings.minScale,
                            maxScale: CBReaderSettings.maxScale,
                            onPreview: _settings.previewFontScale,
                            onCommit: _settings.commitFontScale,
                            overlayBuilder: (_, pending) =>
                                WPinchZoomBadge(scale: pending),
                            builder: (_, locked) => pages(locked),
                          );
                        },
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
      ),
    );
  }
}

/// Registers its element with the reader for as long as its page is mounted,
/// so the reader can ask a live page where it is on screen.
///
/// Natural-height pages killed the offset arithmetic that used to answer "which
/// page am I on"; this answers it from the render tree instead, and only for the
/// two or three pages actually built at any moment.
class _PageProbe extends StatefulWidget {
  const _PageProbe({
    super.key,
    required this.pageNumber,
    required this.onMount,
    required this.onUnmount,
    required this.child,
  });

  final int pageNumber;
  final void Function(int page, BuildContext context) onMount;
  final ValueChanged<int> onUnmount;
  final Widget child;

  @override
  State<_PageProbe> createState() => _PageProbeState();
}

class _PageProbeState extends State<_PageProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMount(widget.pageNumber, context);
  }

  @override
  void dispose() {
    widget.onUnmount(widget.pageNumber);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// One slot in the reader's scroll view, in either mode.
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
  const _PageLoader({required this.pageNumber, this.continuousHeight});
  final int pageNumber;

  /// One screen's height, in continuous mode only — see
  /// [WMushafV4Page.continuousHeight]. Also the height every not-yet-painted
  /// slot reserves: a placeholder that collapsed to nothing would drag the rest
  /// of the Mushaf up under the reader's finger and shove it back down a frame
  /// later, which in a list of natural-height pages reads as the text jumping.
  final double? continuousHeight;

  @override
  State<_PageLoader> createState() => _PageLoaderState();
}

class _PageLoaderState extends State<_PageLoader>
    with AutomaticKeepAliveClientMixin {
  bool _keepAlive = false;

  /// Keep-alive tracking is a plain listener, NOT part of [build]'s trigger.
  ///
  /// It only needs `currentPage`, and folding that into `buildWhen` meant every
  /// page turn rebuilt every page mounted in the list — seven pages' worth of
  /// span trees re-assembled for a number that changes nothing any of them
  /// paint. This slot now rebuilds for its own layout and its own spinner, and
  /// for nothing else.
  StreamSubscription<SMushafReader>? _sub;

  @override
  bool get wantKeepAlive => _keepAlive;

  @override
  void initState() {
    super.initState();
    final cubit = BlocProvider.of<CBMushafReader>(context);
    _keepAlive = _inWindow(cubit.state.currentPage);
    _sub = cubit.stream.listen((s) => _syncKeepAlive(s.currentPage));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool _inWindow(int currentPage) =>
      (widget.pageNumber - currentPage).abs() <= CBMushafReader.preloadRadius;

  void _syncKeepAlive(int currentPage) {
    final next = _inWindow(currentPage);
    if (next == _keepAlive) return;
    _keepAlive = next;
    // `updateKeepAlive` dispatches a KeepAliveNotification, which makes the
    // enclosing AutomaticKeepAlive rebuild — illegal during a build, so defer
    // it to the end of the frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) updateKeepAlive();
    });
  }

  /// Whether this slot is the page being opened right now, and so the one that
  /// owes the reader a spinner.
  bool _spinning(SMushafReader s) =>
      s.currentPage == widget.pageNumber && s.status == LoadStatus.loading;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<CBMushafReader, SMushafReader>(
      buildWhen: (a, b) =>
          a.pages[widget.pageNumber] != b.pages[widget.pageNumber] ||
          _spinning(a) != _spinning(b),
      builder: (context, state) {
        final layout = state.pages[widget.pageNumber];
        if (layout != null) {
          return WMushafV4Page(
            layout: layout,
            continuousHeight: widget.continuousHeight,
          );
        }
        if (_spinning(state)) {
          return SizedBox(
            height: widget.continuousHeight,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        // Outside the warm window (or still resolving) — nothing to paint yet,
        // but in continuous mode the slot must still hold its space.
        return SizedBox(height: widget.continuousHeight ?? 0);
      },
    );
  }
}
