import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/radio/presentation/cubits/cb_radio_player.dart';
import 'package:quran/modules/radio/presentation/cubits/s_radio_player.dart';

/// App-wide floating launcher for the live radio.
///
/// While a station is loaded, a round radio button floats over whatever screen
/// is open. It is:
/// - **Draggable** anywhere on screen. The position is kept while the app runs
///   and is always clamped inside the safe area, so it can't be dropped
///   off-screen or under the status/navigation bars (including after a rotation
///   or a keyboard inset change).
/// - **Tap to expand** into a pill with two actions: stop, and open the radio
///   screen. It collapses again on a second tap, on either action, or after a
///   few idle seconds.
///
/// Stopping ends playback, which clears the player's current station and
/// therefore hides this widget. Opening the radio screen leaves it visible.
///
/// Mounted once in [MaterialApp.router]'s `builder` so it rides above every
/// route. Reads the app-wide [CBRadioPlayer] singleton directly.
class WRadioPeekTab extends StatefulWidget {
  const WRadioPeekTab({super.key});

  @override
  State<WRadioPeekTab> createState() => _WRadioPeekTabState();
}

class _WRadioPeekTabState extends State<WRadioPeekTab>
    with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF007A58);
  static const Duration _autoCollapse = Duration(seconds: 4);

  /// 0 = collapsed bubble, 1 = expanded pill.
  late final AnimationController _expand;
  Timer? _collapseTimer;

  /// Top-left of the button in global coordinates. `null` until the first
  /// layout, when it is seeded at the trailing edge, just above centre.
  Offset? _position;

  /// Guards against a drag being treated as a tap.
  bool _dragged = false;

  @override
  void initState() {
    super.initState();
    _expand = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _expand.dispose();
    super.dispose();
  }

  /// Outer diameter of the collapsed bubble.
  double get _bubble => 54.r;

  /// The white outline is a [Border], which insets the child on every side, so
  /// the content box is 2×[_borderWidth] smaller than the bubble. Sizing the
  /// row's children off [_bubble] is what overflowed it by exactly 4px.
  static const double _borderWidth = 2;

  double get _content => _bubble - _borderWidth * 2;

  /// Width at the current expansion — the pill grows past the bubble by two
  /// action slots plus the gap between them.
  double _width(double expanded) => _bubble + (expanded * (_content * 2 + 8.w));

  void _armAutoCollapse() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(_autoCollapse, _collapse);
  }

  void _collapse() {
    _collapseTimer?.cancel();
    if (mounted) _expand.animateBack(0, curve: Curves.easeOut);
  }

  void _toggleExpanded() {
    if (_expand.value >= 0.5) {
      _collapse();
    } else {
      _expand.animateTo(1, curve: Curves.easeOutCubic);
      _armAutoCollapse();
    }
  }

  /// Reset on tap-DOWN, not on drag start: a plain tap never fires
  /// `onPanStart`, so clearing the flag there left it stuck `true` after the
  /// first drag and silently swallowed every later tap.
  void _onTapDown() {
    _dragged = false;
    _collapseTimer?.cancel();
  }

  void _onDragUpdate(DragUpdateDetails d, Rect bounds, Size size) {
    _dragged = true;
    final current = _position ?? _defaultPosition(bounds, size);
    setState(() {
      _position = _clamp(current + d.delta, bounds, size);
    });
  }

  void _onDragEnd() {
    if (_expand.value > 0) _armAutoCollapse();
  }

  void _openRadio() {
    _collapse();
    // Stays visible on the radio screen — the user asked for it to persist.
    if (!Modular.to.path.startsWith(RoutesNames.radioBase)) {
      Modular.to.pushNamed(RadioRoutes.fullHome());
    }
  }

  Future<void> _stop() async {
    _collapse();
    // Clears the current station, which flips `active` false and hides this.
    await Modular.get<CBRadioPlayer>().stop();
  }

  /// The rectangle the widget may occupy: the screen minus the system insets
  /// and a small margin.
  Rect _bounds(BuildContext context) {
    final media = MediaQuery.of(context);
    final margin = 12.w;
    return Rect.fromLTRB(
      media.padding.left + margin,
      media.padding.top + margin,
      media.size.width - media.padding.right - margin,
      media.size.height - media.padding.bottom - margin,
    );
  }

  Offset _defaultPosition(Rect bounds, Size size) =>
      Offset(bounds.right - size.width, bounds.top + bounds.height * 0.5);

  /// Keeps the whole widget inside [bounds]. Re-applied on every build so a
  /// rotation or an inset change can never strand it off-screen.
  Offset _clamp(Offset value, Rect bounds, Size size) {
    final maxLeft = (bounds.right - size.width).clamp(
      bounds.left,
      bounds.right,
    );
    final maxTop = (bounds.bottom - size.height).clamp(
      bounds.top,
      bounds.bottom,
    );
    return Offset(
      value.dx.clamp(bounds.left, maxLeft),
      value.dy.clamp(bounds.top, maxTop),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBRadioPlayer, SRadioPlayer>(
      bloc: Modular.get<CBRadioPlayer>(),
      builder: (context, state) {
        // Visible whenever a station is loaded — including on the radio screen,
        // so navigating there from the arrow doesn't make it vanish.
        final active =
            state.current != null && state.status != RadioPlayerStatus.idle;
        if (!active) {
          // Reset so the next station starts collapsed at the default anchor.
          if (_expand.value != 0) _expand.value = 0;
          return const SizedBox.shrink();
        }

        return AnimatedBuilder(
          animation: _expand,
          builder: (context, _) {
            final expanded = Curves.easeOutCubic.transform(_expand.value);
            final size = Size(_width(expanded), _bubble);
            final bounds = _bounds(context);
            final position = _clamp(
              _position ?? _defaultPosition(bounds, size),
              bounds,
              size,
            );

            return Positioned(
              left: position.dx,
              top: position.dy,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _onTapDown(),
                onPanDown: (_) => _onTapDown(),
                onPanUpdate: (d) => _onDragUpdate(d, bounds, size),
                onPanEnd: (_) => _onDragEnd(),
                onTap: () {
                  // A drag ends with no tap, but the arena can still deliver
                  // one on a very short drag — ignore those.
                  if (_dragged) return;
                  _toggleExpanded();
                },
                child: _Pill(
                  size: size,
                  bubble: _bubble,
                  content: _content,
                  border: _borderWidth,
                  expanded: expanded,
                  state: state,
                  onStop: _stop,
                  onOpen: _openRadio,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// The floating control itself: a round radio bubble that widens into a pill
/// carrying the stop and open-radio actions.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.size,
    required this.bubble,
    required this.content,
    required this.border,
    required this.expanded,
    required this.state,
    required this.onStop,
    required this.onOpen,
  });

  final Size size;
  final double bubble;

  /// Bubble diameter minus the border on both sides — the height the row's
  /// children actually get.
  final double content;
  final double border;
  final double expanded;
  final SRadioPlayer state;
  final VoidCallback onStop;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: _WRadioPeekTabState._green,
          borderRadius: BorderRadius.circular(bubble / 2),
          border: Border.all(color: Colors.white, width: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: content,
              height: content,
              child: Center(child: _leading()),
            ),
            // The actions fade in as the pill widens; at 0 they take no space.
            // Expanded (not a fixed width) so a rounding difference between the
            // animated container width and the children can never overflow.
            if (expanded > 0.01)
              Expanded(
                child: ClipRect(
                  child: Opacity(
                    opacity: expanded,
                    child: Row(
                      children: [
                        Expanded(
                          child: _Action(
                            tooltip: 'radio_stop'.tr(),
                            icon: Icons.stop_rounded,
                            size: content,
                            onTap: onStop,
                          ),
                        ),
                        Expanded(
                          child: _Action(
                            tooltip: 'radio_open'.tr(),
                            icon: Icons.arrow_forward_rounded,
                            size: content,
                            onTap: onOpen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _leading() {
    if (state.isBusy) {
      return SizedBox(
        width: 20.r,
        height: 20.r,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      );
    }
    return Icon(Icons.radio, color: Colors.white, size: 26.r);
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.tooltip,
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Semantics, NOT Tooltip: this widget is mounted in MaterialApp.builder,
    // above the Navigator that owns the Overlay a Tooltip renders into, so a
    // Tooltip here throws "No Overlay widget found" on every build.
    return Semantics(
      label: tooltip,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        // Height only — the width comes from the enclosing Expanded, so the
        // action can shrink with the pill instead of forcing an overflow.
        child: SizedBox(
          height: size,
          child: Icon(icon, color: Colors.white, size: 22.r),
        ),
      ),
    );
  }
}
