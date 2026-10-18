import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/modules/adhan/services/adhan_scheduler.dart';
import 'package:quran/modules/onboarding/presentation/cubits/s_onboarding.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_lock_screen.dart';
import 'package:quran/modules/prayer/services/prayer_widget_publisher.dart';

class CBOnboarding extends Cubit<SOnboarding> {
  CBOnboarding(
    this._settings,
    this._notifications,
    this._scheduler,
    this._location,
    this._widget,
    this._lockScreen,
  ) : super(const SOnboarding()) {
    final current = _settings.current();
    emit(state.copyWith(
      languageCode: current.lastLanguageCode ?? 'ar',
      locationGranted: current.hasGrantedLocation,
    ));
  }

  final BoxAppSettings _settings;
  final NotificationsService _notifications;
  final AdhanScheduler _scheduler;
  final DSLocation _location;
  final PrayerWidgetPublisher _widget;
  final CBPrayerLockScreen _lockScreen;

  /// Asks for the OS notification permission so adhan/prayer alerts can fire.
  /// Best-effort — scheduling itself is gated on the result elsewhere.
  Future<void> requestNotificationPermission() =>
      _notifications.requestPermission();

  void setPage(int index) => emit(state.copyWith(pageIndex: index));

  void setPrivacyAccepted(bool accepted) =>
      emit(state.copyWith(privacyAccepted: accepted));

  Future<void> setLanguage(String code) async {
    await _settings.setLanguageCode(code);
    await LocalizeAndTranslate.setLanguageCode(code);
    emit(state.copyWith(languageCode: code));
    // The home-screen widget carries its own strings.
    unawaited(_widget.republish());
  }

  /// Shows the OS location prompt straight away and records the real answer.
  ///
  /// Backs the onboarding "Allow" button: the user tapped allow, so the system
  /// dialog belongs on that tap rather than deferred to the first Prayer Times
  /// run. A refusal is not fatal — Prayer Times still asks again when it needs
  /// coordinates, and the user can grant it from settings.
  Future<bool> requestLocationPermission() async {
    final granted = await _location.requestPermission();
    await setLocationOptIn(granted);
    return granted;
  }

  /// Records the outcome of the location step — the OS answer on the allow
  /// path, plain intent (`false`) when the user skips.
  Future<void> setLocationOptIn(bool granted) async {
    await _settings.setHasGrantedLocation(granted);
    emit(state.copyWith(didRequestLocation: true, locationGranted: granted));
  }

  /// Finishes onboarding and re-runs the companion schedulers.
  ///
  /// Boot registers the azkar/quran feed, the salawat reminders and the hourly
  /// zekr before the user has answered the notification prompt, so on a first
  /// install those requests are placed unauthorized. Repeating them here — once
  /// the grant is settled — is what makes the first day of an install actually
  /// deliver anything. Best-effort: the reconcile swallows its own failures.
  ///
  /// Also where a fresh install gets its one default that lives outside Hive,
  /// the lock-screen prayer notification — see [_pinLockScreenByDefault].
  Future<void> markComplete() async {
    await _pinLockScreenByDefault();
    await _settings.setHasSeenOnboarding(true);
    await _scheduler.reconcileCompanionNotifications();
  }

  /// Switches the lock-screen prayer notification on (Android), so a new
  /// install starts with every feature on and the closing onboarding screen
  /// can say so; Settings switches it off.
  ///
  /// Its switch is a native preference whose default has to stay off — an
  /// upgrade must not start pinning a notification nobody asked for — so the
  /// fresh-install default is applied here, once, rather than in the default.
  /// Only with the notification grant already in hand: switching on without it
  /// would raise the OS prompt a second time, right after the user declined.
  Future<void> _pinLockScreenByDefault() async {
    if (!await _notifications.hasPermission()) return;
    await _lockScreen.setEnabled(true);
  }
}
