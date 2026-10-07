import 'dart:async';

import 'package:flutter/widgets.dart';

/// Nudges its owner whenever the local calendar day may have turned over: at
/// local midnight while the app is in the foreground, and on every return to
/// the foreground.
///
/// The resume hook is what carries the common case — a phone put down at night
/// and picked up in the morning. A suspended app's timers are frozen, so the
/// midnight timer alone can't be trusted to have fired by then.
///
/// [onCheck] is a nudge, not a promise that the date changed: it must be cheap,
/// idempotent and compare day stamps itself. Owners are long-lived singletons,
/// so [dispose] it in their `close`.
class DayChangeWatcher {
  DayChangeWatcher(this.onCheck) {
    _lifecycle = AppLifecycleListener(onResume: _fire);
    _arm();
  }

  final VoidCallback onCheck;
  late final AppLifecycleListener _lifecycle;
  Timer? _midnight;

  /// Time from [now] to the next local midnight. Built from calendar fields
  /// rather than `+ 24h` so a DST shift lands on midnight, not an hour off.
  @visibleForTesting
  static Duration untilNextDay(DateTime now) =>
      DateTime(now.year, now.month, now.day + 1).difference(now);

  void _arm() {
    _midnight?.cancel();
    _midnight = Timer(untilNextDay(DateTime.now()), _fire);
  }

  void _fire() {
    _arm();
    onCheck();
  }

  void dispose() {
    _midnight?.cancel();
    _lifecycle.dispose();
  }
}
