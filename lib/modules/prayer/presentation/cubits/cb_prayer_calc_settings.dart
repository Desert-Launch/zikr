import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/core/services/logging/app_logger.dart';
import 'package:quran/modules/prayer/data/sources/local/box_prayer_settings.dart';
import 'package:quran/modules/prayer/domain/entities/e_asr_school.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_mode.dart';
import 'package:quran/modules/prayer/domain/entities/e_high_latitude_rule.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_adjustments.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_settings.dart';
import 'package:quran/modules/prayer/domain/usecases/uc_get_calculation_methods.dart';
import 'package:quran/modules/prayer/presentation/cubits/cb_prayer_times.dart';
import 'package:quran/modules/prayer/presentation/cubits/s_prayer_calc_settings.dart';

/// Owns the calculation preferences: mode, authority, Asr school,
/// high-latitude rule and minute corrections.
///
/// Every setter persists immediately and then, on a short debounce, asks
/// [CBPrayerTimes] to re-resolve — which also rebuilds the notification
/// window. The debounce is what keeps six taps on a minute stepper from
/// firing six refetches and six full schedule rebuilds.
class CBPrayerCalcSettings extends Cubit<SPrayerCalcSettings> {
  CBPrayerCalcSettings({
    required BoxPrayerSettings box,
    required UCGetCalculationMethods getMethods,
    required CBPrayerTimes prayerTimes,
  }) : _box = box,
       _getMethods = getMethods,
       _prayerTimes = prayerTimes,
       super(const SPrayerCalcSettings());

  final BoxPrayerSettings _box;
  final UCGetCalculationMethods _getMethods;
  final CBPrayerTimes _prayerTimes;

  /// Long enough to absorb a run of stepper taps, short enough that the
  /// screen's times are already correct by the time the user navigates back.
  static const Duration _applyDelay = Duration(milliseconds: 900);

  Timer? _applyTimer;

  Future<void> load() async {
    final (resolvedId, resolvedName) = _box.resolvedMethod();
    emit(
      state.copyWith(
        settings: _box.calculation(),
        resolvedMethodId: resolvedId,
        resolvedMethodName: resolvedName,
        methodsLoading: state.methods.isEmpty,
      ),
    );

    final result = await _getMethods();
    if (isClosed) return;
    result.fold(
      (failure) {
        AppLogger.warning(
          'Calculation methods unavailable: ${failure.message}',
          tag: 'CBPrayerCalcSettings',
        );
        emit(state.copyWith(methodsLoading: false));
      },
      (methods) => emit(
        state.copyWith(methods: methods, methodsLoading: false),
      ),
    );
  }

  /// Back to letting Aladhan choose. The pinned id is kept in storage so
  /// returning to manual restores it, but [EPrayerSettings.effectiveMethodId]
  /// stops sending it — which is the whole difference between the two modes.
  Future<void> useAutomatic() =>
      _apply(state.settings.copyWith(mode: ECalculationMode.automatic));

  /// Pins [methodId] and switches to manual in one step — selecting an
  /// authority is the act of choosing manual, and making the user flip a
  /// separate switch afterwards is how a picked method ends up not applied.
  Future<void> useMethod(int methodId) => _apply(
    state.settings.copyWith(
      mode: ECalculationMode.manual,
      manualMethodId: methodId,
    ),
  );

  Future<void> setAsrSchool(EAsrSchool school) =>
      _apply(state.settings.copyWith(asrSchool: school));

  Future<void> setHighLatitudeRule(EHighLatitudeRule rule) =>
      _apply(state.settings.copyWith(highLatitudeRule: rule));

  Future<void> setAdjustments(EPrayerAdjustments adjustments) =>
      _apply(state.settings.copyWith(adjustments: adjustments));

  Future<void> resetAdjustments() =>
      _apply(state.settings.copyWith(adjustments: EPrayerAdjustments.none));

  /// Persists [next] and schedules the re-resolve.
  Future<void> _apply(EPrayerSettings next) async {
    if (next == state.settings) return;
    emit(state.copyWith(settings: next));
    await _box.saveCalculation(next);
    _scheduleApply();
  }

  void _scheduleApply() {
    _applyTimer?.cancel();
    _applyTimer = Timer(_applyDelay, () {
      unawaited(_prayerTimes.onSettingsChanged());
    });
  }

  @override
  Future<void> close() {
    // Don't let a pending debounce die with the screen — the user changed a
    // setting and left; the times and the adhan window still have to follow.
    if (_applyTimer?.isActive ?? false) {
      _applyTimer?.cancel();
      unawaited(_prayerTimes.onSettingsChanged());
    }
    return super.close();
  }
}
