import 'package:flutter/widgets.dart';

/// Where the ayah being recited is on screen.
///
/// The page wraps the first line that carries the playing verse in a
/// [WPlayingAyahAnchor], which records its context here; the reader looks that
/// context up to scroll the verse into view as the recitation moves.
///
/// A registry rather than a `GlobalKey`: the key would have to be shared by
/// every page that might hold the verse, and two widgets holding one GlobalKey
/// is a crash — whereas a second registration here simply wins, and a stale
/// entry is dropped the moment its element is gone.
class PlayingAyahAnchors {
  PlayingAyahAnchors._();

  static final Map<String, BuildContext> _byAyah = <String, BuildContext>{};

  /// The line where [ayahKey] begins on [page], or null while that page is not
  /// mounted.
  ///
  /// Keyed by page as well as verse because a verse that runs over a page break
  /// is carried by two pages, both of which may be built at once — the reader
  /// wants the one it resolved the verse to, not whichever mounted last.
  static BuildContext? contextFor({required int page, required String ayahKey}) {
    final key = _key(page, ayahKey);
    final context = _byAyah[key];
    if (context == null) return null;
    if (!context.mounted) {
      _byAyah.remove(key);
      return null;
    }
    return context;
  }

  static String _key(int page, String ayahKey) => '$page#$ayahKey';

  static void _register(int page, String ayahKey, BuildContext context) =>
      _byAyah[_key(page, ayahKey)] = context;

  static void _unregister(int page, String ayahKey, BuildContext context) {
    final key = _key(page, ayahKey);
    if (identical(_byAyah[key], context)) _byAyah.remove(key);
  }
}

/// Marks its child as the place the ayah [ayahKey] begins, for as long as it is
/// mounted. Renders the child untouched — it is a position, not a decoration.
class WPlayingAyahAnchor extends StatefulWidget {
  const WPlayingAyahAnchor({
    required this.page,
    required this.ayahKey,
    required this.child,
    super.key,
  });

  /// Mushaf page this line is printed on.
  final int page;

  /// `surah:ayah` of the verse this line opens.
  final String ayahKey;

  final Widget child;

  @override
  State<WPlayingAyahAnchor> createState() => _WPlayingAyahAnchorState();
}

class _WPlayingAyahAnchorState extends State<WPlayingAyahAnchor> {
  @override
  void initState() {
    super.initState();
    PlayingAyahAnchors._register(widget.page, widget.ayahKey, context);
  }

  @override
  void didUpdateWidget(covariant WPlayingAyahAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The recitation moved on and this element was reused for the next verse.
    if (oldWidget.ayahKey == widget.ayahKey && oldWidget.page == widget.page) {
      return;
    }
    PlayingAyahAnchors._unregister(oldWidget.page, oldWidget.ayahKey, context);
    PlayingAyahAnchors._register(widget.page, widget.ayahKey, context);
  }

  @override
  void dispose() {
    PlayingAyahAnchors._unregister(widget.page, widget.ayahKey, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
