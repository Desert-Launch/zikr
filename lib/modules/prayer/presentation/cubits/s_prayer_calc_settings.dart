import 'package:equatable/equatable.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_method.dart';
import 'package:quran/modules/prayer/domain/entities/e_calculation_mode.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer_settings.dart';

/// Calculation-settings screen state.
class SPrayerCalcSettings extends Equatable {
  const SPrayerCalcSettings({
    this.settings = EPrayerSettings.defaults,
    this.methods = const [],
    this.methodsLoading = false,
    this.resolvedMethodId,
    this.resolvedMethodName,
  });

  final EPrayerSettings settings;

  /// The authorities offered in the picker, from `/v1/methods` (cached).
  final List<ECalculationMethod> methods;
  final bool methodsLoading;

  /// What Aladhan actually used on the last successful fetch. In automatic
  /// mode this is the whole answer to "which authority am I on?" — without it
  /// the row could only say "Automatic", which explains nothing when the
  /// user's times differ from their mosque's.
  final int? resolvedMethodId;
  final String? resolvedMethodName;

  /// The method currently in force: the pinned one in manual mode, otherwise
  /// whatever Aladhan resolved.
  int? get activeMethodId =>
      settings.mode == ECalculationMode.manual
      ? settings.manualMethodId
      : resolvedMethodId;

  /// Human-readable name for [activeMethodId], preferring the live list so a
  /// renamed authority shows its current name.
  String get activeMethodName {
    final id = activeMethodId;
    if (id == null) return '';
    for (final method in methods) {
      if (method.id == id) return method.name;
    }
    return resolvedMethodName ?? '';
  }

  SPrayerCalcSettings copyWith({
    EPrayerSettings? settings,
    List<ECalculationMethod>? methods,
    bool? methodsLoading,
    int? resolvedMethodId,
    String? resolvedMethodName,
  }) => SPrayerCalcSettings(
    settings: settings ?? this.settings,
    methods: methods ?? this.methods,
    methodsLoading: methodsLoading ?? this.methodsLoading,
    resolvedMethodId: resolvedMethodId ?? this.resolvedMethodId,
    resolvedMethodName: resolvedMethodName ?? this.resolvedMethodName,
  );

  @override
  List<Object?> get props => [
    settings,
    methods,
    methodsLoading,
    resolvedMethodId,
    resolvedMethodName,
  ];
}
