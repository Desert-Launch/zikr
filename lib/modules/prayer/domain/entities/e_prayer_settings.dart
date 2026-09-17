import 'package:equatable/equatable.dart';
import 'package:quran/modules/prayer/domain/entities/e_asr_school.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_mode.dart';
import 'package:quran/modules/prayer/domain/entities/e_high_latitude_rule.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_adjustments.dart';

/// Everything the user can change that alters a prayer time.
///
/// Deliberately a domain value with no persistence and no API knowledge:
/// `BoxPrayerSettings` reads/writes it, `AladhanQueryBuilder` turns it into
/// query parameters, and nothing else needs to know either shape.
class EPrayerSettings extends Equatable {
  const EPrayerSettings({
    this.mode = ECalculationMode.automatic,
    this.manualMethodId,
    this.asrSchool = EAsrSchool.standard,
    this.highLatitudeRule = EHighLatitudeRule.automatic,
    this.adjustments = EPrayerAdjustments.none,
  });

  /// The safe defaults an existing install migrates onto: let Aladhan choose
  /// the authority, standard Asr, the API's own high-latitude behaviour, and
  /// no minute corrections.
  static const EPrayerSettings defaults = EPrayerSettings();

  final ECalculationMode mode;

  /// The authority the user pinned. Kept across a switch back to automatic so
  /// re-selecting "manual" restores their choice — but see [effectiveMethodId]:
  /// it is not sent while the mode is automatic.
  final int? manualMethodId;

  final EAsrSchool asrSchool;
  final EHighLatitudeRule highLatitudeRule;
  final EPrayerAdjustments adjustments;

  /// The method id to actually send, or null when Aladhan should choose.
  ///
  /// This is the guard against the bug the whole automatic mode would
  /// otherwise have: a user who once picked a method manually and then went
  /// back to Automatic must stop sending it, or "Automatic" quietly stays
  /// pinned to wherever they used to live.
  int? get effectiveMethodId =>
      mode == ECalculationMode.manual ? manualMethodId : null;

  /// A compact fingerprint of everything that changes the resulting times.
  ///
  /// It is part of every cache key, so flipping the school, pinning a method,
  /// choosing a high-latitude rule or tuning a minute lands on a different
  /// entry instead of reading back times computed under the old settings.
  String get cacheSignature {
    final method = effectiveMethodId?.toString() ?? 'auto';
    final tune = adjustments.isZero ? '0' : adjustments.tuneParam;
    return 'm$method-s${asrSchool.name}-h${highLatitudeRule.name}-t$tune';
  }

  EPrayerSettings copyWith({
    ECalculationMode? mode,
    int? manualMethodId,
    bool clearManualMethodId = false,
    EAsrSchool? asrSchool,
    EHighLatitudeRule? highLatitudeRule,
    EPrayerAdjustments? adjustments,
  }) => EPrayerSettings(
    mode: mode ?? this.mode,
    manualMethodId: clearManualMethodId
        ? null
        : (manualMethodId ?? this.manualMethodId),
    asrSchool: asrSchool ?? this.asrSchool,
    highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
    adjustments: adjustments ?? this.adjustments,
  );

  @override
  List<Object?> get props => [
    mode,
    manualMethodId,
    asrSchool,
    highLatitudeRule,
    adjustments,
  ];
}
