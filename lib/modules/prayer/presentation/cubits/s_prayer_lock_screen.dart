import 'package:equatable/equatable.dart';

/// How this device can keep prayer times on the lock screen.
enum ELockScreenMode {
  /// Nothing to offer — iOS 15, or another platform.
  none,

  /// Android: the app pins an ongoing notification; Settings has a switch.
  notification,

  /// iOS 16+: a Lock Screen widget only the user can add; Settings says how.
  widget,
}

class SPrayerLockScreen extends Equatable {
  const SPrayerLockScreen({
    this.mode = ELockScreenMode.none,
    this.enabled = false,
    this.busy = false,
  });

  final ELockScreenMode mode;

  /// The Android switch. Always false in the other modes.
  final bool enabled;

  /// A switch is in flight (possibly behind the notification prompt).
  final bool busy;

  bool get available => mode != ELockScreenMode.none;

  SPrayerLockScreen copyWith({bool? enabled, bool? busy}) => SPrayerLockScreen(
    mode: mode,
    enabled: enabled ?? this.enabled,
    busy: busy ?? this.busy,
  );

  @override
  List<Object?> get props => [mode, enabled, busy];
}
