import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_prayer_lock_screen.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_lock_screen.dart';

/// Prayer times on the lock screen: the Android switch for the pinned
/// notification (see [DSPrayerLockScreen]), and which form the feature takes
/// on this device at all. A singleton so the boot step and the Settings row
/// share one state.
class CBPrayerLockScreen extends Cubit<SPrayerLockScreen> {
  CBPrayerLockScreen({
    required DSPrayerLockScreen lockScreen,
    required NotificationsService notifications,
  }) : _lockScreen = lockScreen,
       _notifications = notifications,
       super(SPrayerLockScreen(mode: _modeOf(lockScreen)));

  final DSPrayerLockScreen _lockScreen;
  final NotificationsService _notifications;

  static ELockScreenMode _modeOf(DSPrayerLockScreen lockScreen) {
    if (lockScreen.canPin) return ELockScreenMode.notification;
    if (lockScreen.hasLockScreenWidget) return ELockScreenMode.widget;
    return ELockScreenMode.none;
  }

  /// Reads the stored switch and, when it is on, re-posts the notification.
  Future<void> load() async {
    if (state.mode != ELockScreenMode.notification) return;
    final enabled = await _lockScreen.isEnabled();
    emit(state.copyWith(enabled: enabled));
    if (enabled) await _lockScreen.refresh();
  }

  /// False when it could not be switched on because notifications are
  /// blocked — the caller tells the user. The switch then stays off.
  Future<bool> setEnabled(bool enabled) async {
    if (state.mode != ELockScreenMode.notification || state.busy) return true;
    emit(state.copyWith(busy: true));
    // Without the notification permission there is nothing to show; ask
    // first, so a fresh grant lands before the platform checks for it.
    if (enabled && !await _notifications.hasPermission()) {
      await _notifications.requestPermission();
    }
    final applied = await _lockScreen.setEnabled(enabled);
    emit(
      state.copyWith(enabled: applied ? enabled : state.enabled, busy: false),
    );
    return applied;
  }
}
