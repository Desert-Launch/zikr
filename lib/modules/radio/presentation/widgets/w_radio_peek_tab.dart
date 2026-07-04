import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/radio/presentation/cubits/cb_radio_player.dart';
import 'package:quran/modules/radio/presentation/cubits/s_radio_player.dart';

/// App-wide floating launcher for the live radio.
///
/// While a station is loaded, a small radio tab clings to the trailing screen
/// edge, mostly tucked off-screen. Dragging it inward reveals it fully (it snaps
/// back after a moment); tapping it opens the radio screen. Hidden entirely when
/// nothing is playing or while the radio screen is already open.
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
  static const Duration _autoCollapse = Duration(seconds: 3);

  /// 0 = peeking (half-hidden), 1 = fully revealed.
  late final AnimationController _reveal;
  Timer? _collapseTimer;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _reveal.dispose();
    super.dispose();
  }

  bool get _onRadioScreen =>
      Modular.to.path.startsWith(RoutesNames.radioBase);

  void _armAutoCollapse() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(_autoCollapse, () {
      if (mounted) _reveal.animateBack(0, curve: Curves.easeOut);
    });
  }

  void _onDragUpdate(DragUpdateDetails d, double travel) {
    _collapseTimer?.cancel();
    // Trailing-edge tab: dragging left (negative dx) reveals it.
    _reveal.value = (_reveal.value - d.delta.dx / travel).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails d) {
    final flungOpen = d.velocity.pixelsPerSecond.dx < -250;
    final flungShut = d.velocity.pixelsPerSecond.dx > 250;
    final open = flungOpen || (!flungShut && _reveal.value >= 0.5);
    _reveal.animateTo(open ? 1 : 0, curve: Curves.easeOut);
    if (open) _armAutoCollapse();
  }

  void _open() {
    _collapseTimer?.cancel();
    if (!_onRadioScreen) Modular.to.pushNamed(RadioRoutes.fullHome());
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild on every navigation (the router delegate notifies its listeners),
    // so the on-radio-screen check below always reflects the live route and can
    // never get stuck. Then rebuild on player-state changes via BlocBuilder.
    return AnimatedBuilder(
      animation: Modular.routerConfig.routerDelegate,
      builder: (context, _) {
        return BlocBuilder<CBRadioPlayer, SRadioPlayer>(
          bloc: Modular.get<CBRadioPlayer>(),
          builder: (context, state) => _buildTab(context, state),
        );
      },
    );
  }

  Widget _buildTab(BuildContext context, SRadioPlayer state) {
        // Visible while a station is loaded — except on the radio screen itself,
        // where it would be redundant.
        final active = state.current != null &&
            state.status != RadioPlayerStatus.idle &&
            !_onRadioScreen;

        final size = 54.r;
        // Most of the tab tucks off the trailing edge when peeking — only a
        // small sliver shows until the user drags it in.
        final peekRight = -size * 0.62;
        final openRight = 14.w;
        final travel = openRight - peekRight;
        final top = MediaQuery.sizeOf(context).height * 0.52;

        return AnimatedBuilder(
          animation: _reveal,
          builder: (context, _) {
            final right = active
                ? lerpDouble(peekRight, openRight, _reveal.value)
                : -(size + 24);
            return Positioned(
              top: top,
              right: right,
              child: AnimatedOpacity(
                opacity: active ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: IgnorePointer(
                  ignoring: !active,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _open,
                    onHorizontalDragStart: (_) => _collapseTimer?.cancel(),
                    onHorizontalDragUpdate: (d) => _onDragUpdate(d, travel),
                    onHorizontalDragEnd: _onDragEnd,
                    child: _TabButton(size: size, state: state),
                  ),
                ),
              ),
            );
          },
        );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.size, required this.state});

  final double size;
  final SRadioPlayer state;

  @override
  Widget build(BuildContext context) {
    final busy = state.isBusy;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _WRadioPeekTabState._green,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: busy
          ? SizedBox(
              width: 20.r,
              height: 20.r,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Icon(Icons.radio, color: Colors.white, size: 26.r),
    );
  }
}
