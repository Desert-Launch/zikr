import 'package:equatable/equatable.dart';

/// Per-prayer minute corrections, for when the local mosque runs a couple of
/// minutes off the astronomical calculation everyone agrees on.
///
/// Advanced and entirely optional — every value defaults to zero and the app
/// never asks the user to set one. When all nine are zero the `tune` parameter
/// is left off the request completely, so an untouched install sends exactly
/// what it sent before this setting existed.
class EPrayerAdjustments extends Equatable {
  const EPrayerAdjustments({
    this.imsak = 0,
    this.fajr = 0,
    this.sunrise = 0,
    this.dhuhr = 0,
    this.asr = 0,
    this.maghrib = 0,
    this.sunset = 0,
    this.isha = 0,
    this.midnight = 0,
  });

  /// The default: no correction anywhere.
  static const EPrayerAdjustments none = EPrayerAdjustments();

  /// How many values [toList]/[fromList] carry — Aladhan's `tune` takes
  /// exactly this many, in this order.
  static const int slotCount = 9;

  final int imsak;
  final int fajr;
  final int sunrise;
  final int dhuhr;
  final int asr;
  final int maghrib;
  final int sunset;
  final int isha;
  final int midnight;

  bool get isZero => toList().every((v) => v == 0);

  /// Aladhan's `tune` ordering — Imsak, Fajr, Sunrise, Dhuhr, Asr, Maghrib,
  /// **Sunset**, Isha, Midnight.
  ///
  /// Note that Maghrib comes *before* Sunset here, which is not clock order;
  /// getting the two the wrong way round shifts the sunset marker instead of
  /// the prayer. The order lives in this one method and the test that pins it.
  List<int> toList() => [
    imsak,
    fajr,
    sunrise,
    dhuhr,
    asr,
    maghrib,
    sunset,
    isha,
    midnight,
  ];

  /// The `tune` query value, e.g. `0,2,0,0,0,1,0,0,0`.
  String get tuneParam => toList().join(',');

  /// Rebuilds from a persisted list, tolerating a short/absent/oversized one
  /// (a record written before a slot existed reads as zero).
  factory EPrayerAdjustments.fromList(List<int>? values) {
    if (values == null || values.isEmpty) return none;
    int at(int i) => i < values.length ? values[i] : 0;
    return EPrayerAdjustments(
      imsak: at(0),
      fajr: at(1),
      sunrise: at(2),
      dhuhr: at(3),
      asr: at(4),
      maghrib: at(5),
      sunset: at(6),
      isha: at(7),
      midnight: at(8),
    );
  }

  EPrayerAdjustments copyWith({
    int? imsak,
    int? fajr,
    int? sunrise,
    int? dhuhr,
    int? asr,
    int? maghrib,
    int? sunset,
    int? isha,
    int? midnight,
  }) => EPrayerAdjustments(
    imsak: imsak ?? this.imsak,
    fajr: fajr ?? this.fajr,
    sunrise: sunrise ?? this.sunrise,
    dhuhr: dhuhr ?? this.dhuhr,
    asr: asr ?? this.asr,
    maghrib: maghrib ?? this.maghrib,
    sunset: sunset ?? this.sunset,
    isha: isha ?? this.isha,
    midnight: midnight ?? this.midnight,
  );

  @override
  List<Object?> get props => toList();
}
