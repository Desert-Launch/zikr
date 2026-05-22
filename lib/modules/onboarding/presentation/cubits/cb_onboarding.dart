import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/data/sources/local/box_app_settings.dart';
import 'package:quran/modules/onboarding/presentation/cubits/s_onboarding.dart';

class CBOnboarding extends Cubit<SOnboarding> {
  CBOnboarding(this._settings) : super(const SOnboarding()) {
    final current = _settings.current();
    emit(state.copyWith(
      languageCode: current.lastLanguageCode ?? 'ar',
      locationGranted: current.hasGrantedLocation,
    ));
  }

  final BoxAppSettings _settings;

  void setPage(int index) => emit(state.copyWith(pageIndex: index));

  Future<void> setLanguage(String code) async {
    await _settings.setLanguageCode(code);
    await LocalizeAndTranslate.setLanguageCode(code);
    emit(state.copyWith(languageCode: code));
  }

  /// Records whether the user opted into location (the actual platform
  /// permission request happens later, when Prayer Times first runs).
  Future<void> setLocationOptIn(bool granted) async {
    await _settings.setHasGrantedLocation(granted);
    emit(state.copyWith(didRequestLocation: true, locationGranted: granted));
  }

  Future<void> markComplete() async {
    await _settings.setHasSeenOnboarding(true);
  }
}
