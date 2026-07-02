import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/widgets/w_localize_rotation.dart';
import 'package:quran/core/widgets/w_shared_scaffold.dart';
import 'package:quran/modules/live/domain/entities/e_live_channel.dart';
import 'package:quran/modules/live/presentation/cubits/cb_live.dart';
import 'package:quran/modules/live/presentation/cubits/s_live.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Haramain live broadcasts. Provides [CBLive], which resolves the selected
/// channel's CURRENT live video id from the channel itself (see [CBLive]) and
/// falls back to a last-known-good id when that lookup fails.
class SNLive extends StatelessWidget {
  const SNLive({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CBLive>(
      create: (_) => Modular.get<CBLive>()..open(ELiveChannel.makkah),
      child: const _LiveView(),
    );
  }
}

/// A single embedded [WebView] fills the screen and plays whichever id [CBLive]
/// has resolved for the selected channel; the toggle re-resolves and reloads it.
/// `controls=0` keeps the surface immersive and the app chrome (header +
/// switcher) overlays on top.
///
/// Tapping the video toggles the chrome and the system bars. The screen forces
/// landscape while open and restores portrait + chrome on exit. All chrome uses
/// fixed logical sizes (NOT flutter_screenutil) because screenutil rescales its
/// units on rotation and the rest of the app is portrait-locked.
class _LiveView extends StatefulWidget {
  const _LiveView();

  @override
  State<_LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends State<_LiveView> {
  static const _green = Color(0xFF0D7E5E);

  /// HTML page origin loaded with the iframe. Matching the nocookie embed
  /// domain gives YouTube a valid referrer and avoids the player-config errors
  /// (153 / 152) seen when the embed is opened as a bare top-level page.
  static const _origin = 'https://www.youtube-nocookie.com';

  late final WebViewController _controller;

  /// The id currently loaded in the WebView — drives the watch-page fallback and
  /// the external-open action.
  String? _videoId;
  bool _loading = true;
  bool _error = false;
  bool _usedFallback = false;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    // Live broadcasts read best in landscape; portrait restored in dispose.
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    // The first load is driven by CBLive once it resolves the current id.
    _controller = _buildController();
  }

  @override
  void dispose() {
    // Restore the app-wide portrait lock (see main.dart) and the system bars.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  WebViewController _buildController() {
    // iOS (WKWebView) needs inline playback enabled so the video stays in-app
    // instead of jumping to the native fullscreen player.
    final PlatformWebViewControllerCreationParams params = WebViewPlatform.instance is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          )
        : const PlatformWebViewControllerCreationParams();

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _error = false;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (!mounted || !(error.isForMainFrame ?? true)) return;
            // First failure → load the watch-page fallback in-place. Only if
            // that also fails do we surface the error state.
            final id = _videoId;
            if (!_usedFallback && id != null) {
              _usedFallback = true;
              _controller.loadRequest(Uri.parse(ELiveChannel.watchUrlFor(id)));
            } else {
              setState(() {
                _loading = false;
                _error = true;
              });
            }
          },
        ),
      );

    // Android: allow the live stream to autoplay without a tap (the tap layer
    // is reserved for toggling the chrome, so there is no in-player play button).
    if (controller.platform is AndroidWebViewController) {
      (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }
    return controller;
  }

  /// Wraps the embed in an iframe served from [_origin]; the base URL gives the
  /// player a valid referrer so it loads instead of erroring.
  String _embedHtml(String src) =>
      '''<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>
  html, body { margin: 0; padding: 0; height: 100%; width: 100%; background: #000; overflow: hidden; }
  .frame { position: absolute; inset: 0; }
  .frame iframe { width: 100%; height: 100%; border: 0; }
</style>
</head>
<body>
  <div class="frame">
    <iframe src="$src"
      title="YouTube video player"
      frameborder="0"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
      referrerpolicy="strict-origin-when-cross-origin"
      allowfullscreen></iframe>
  </div>
</body>
</html>''';

  /// Loads the resolved [id] into the embed. Driven by the [CBLive] listener.
  void _loadVideo(String id) {
    _videoId = id;
    _usedFallback = false;
    setState(() {
      _loading = true;
      _error = false;
    });
    _controller.loadHtmlString(_embedHtml(ELiveChannel.embedUrlFor(id)), baseUrl: _origin);
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    SystemChrome.setEnabledSystemUIMode(_chromeVisible ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky);
  }

  Future<void> _openInYoutube() async {
    final id = _videoId ?? BlocProvider.of<CBLive>(context).state.channel.videoId;
    final uri = Uri.parse(ELiveChannel.watchUrlFor(id));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CBLive, SLive>(
      // Reload the WebView whenever a fresh id is resolved (or re-resolved).
      listenWhen: (prev, curr) =>
          curr.status == LiveResolveStatus.ready &&
          curr.videoId != null &&
          (prev.videoId != curr.videoId || prev.status != curr.status),
      listener: (_, state) => _loadVideo(state.videoId ?? ''),
      builder: (context, state) {
        // Busy = resolving the id OR the WebView is still loading the page.
        final busy = state.status == LiveResolveStatus.resolving || _loading;
        return WSharedScaffold(
          backgroundColor: Colors.black,
          withSafeArea: false,
          padding: EdgeInsets.zero,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Video (or error) fills the whole screen.
              ColoredBox(
                color: Colors.black,
                child: Center(child: _error ? _errorView(context, state.channel) : _video(busy)),
              ),
              // 2. Transparent tap layer over the video toggles the chrome. Skipped
              //    in the error state so the retry/open buttons stay tappable.
              if (!_error)
                Positioned.fill(
                  child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _toggleChrome),
                ),
              // 3. Chrome (header + switcher) overlays the top, on top of the tap
              //    layer so its buttons win taps. Fades + ignores pointers when hidden.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !_chromeVisible,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _chromeVisible ? 1 : 0,
                    child: _chrome(context, state.channel),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _video(bool busy) {
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _controller),
        if (busy)
          const ColoredBox(
            color: Colors.black,
            child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.6)),
          ),
      ],
    );
  }

  Widget _chrome(BuildContext context, ELiveChannel channel) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC000000), Color(0x00000000)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(title: 'live_title'.tr(), onOpenExternal: _openInYoutube),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: _StreamToggle(
              channels: ELiveChannel.all,
              selectedId: channel.id,
              accent: _green,
              onSelect: (c) => BlocProvider.of<CBLive>(context).select(c),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView(BuildContext context, ELiveChannel channel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 48),
          const SizedBox(height: 12),
          Text(
            'live_error'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Re-resolve the current live id and reload from scratch.
              _PillButton(
                label: 'live_retry'.tr(),
                filled: true,
                onTap: () => BlocProvider.of<CBLive>(context).open(channel),
              ),
              const SizedBox(width: 12),
              _PillButton(label: 'live_open_youtube'.tr(), filled: false, onTap: _openInYoutube),
            ],
          ),
        ],
      ),
    );
  }
}

/// Slim branded header with fixed sizing (orientation-safe). Lays out RTL:
/// back on the right, title centered, external-open on the left.
class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onOpenExternal});

  final String title;
  final VoidCallback onOpenExternal;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              WLocalizeRotation(
                reverse: true,
                child: IconButton(
                  onPressed: Modular.to.pop,
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'live_open_youtube'.tr(),
                onPressed: onOpenExternal,
                icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-segment pill toggle (Makkah / Madinah). Fixed sizing (orientation-safe).
class _StreamToggle extends StatelessWidget {
  const _StreamToggle({required this.channels, required this.selectedId, required this.accent, required this.onSelect});

  final List<ELiveChannel> channels;
  final String selectedId;
  final Color accent;
  final ValueChanged<ELiveChannel> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          for (final ch in channels)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(ch),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ch.id == selectedId ? accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    ch.shortTitleKey.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ch.id == selectedId ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small fixed-size pill button used in the error view.
class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.filled, required this.onTap});

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF0D7E5E) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: filled ? null : Border.all(color: Colors.white70),
        ),
        child: Text(
          label,
          style: TextStyle(color: filled ? Colors.white : Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
