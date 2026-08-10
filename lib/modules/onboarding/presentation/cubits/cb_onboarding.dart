import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/core/services/notifications/notifications_service.dart';
import 'package:quran/modules/adhan/services/adhan_scheduler.dart';
import 'package:quran/modules/onboarding/presentation/cubits/s_onboarding.dart';
import 'package:quran/modules/prayer/data/datasources/local/ds_location.dart';

class CBOnboarding extends Cubit<SOnboarding> {
  CBOnboarding(
    this._settings,
    this._notifications,
    this._scheduler,
    this._location,
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

  /// Asks for the OS notification permission so adhan/prayer alerts can fire.
  /// Best-effort — scheduling itself is gated on the result elsewhere.
  Future<void> requestNotificationPermission() =>
      _notifications.requestPermission();

  void setPage(int index) => emit(state.copyWith(pageIndex: index));

  Future<void> setLanguage(String code) async {
    await _settings.setLanguageCode(code);
    await LocalizeAndTranslate.setLanguageCode(code);
    emit(state.copyWith(languageCode: code));
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
  Future<void> markComplete() async {
    await _settings.setHasSeenOnboarding(true);
    await _scheduler.reconcileCompanionNotifications();
  }
}
