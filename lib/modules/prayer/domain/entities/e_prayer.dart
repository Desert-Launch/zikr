enum EPrayer { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension EPrayerX on EPrayer {
  String get key => switch (this) {
        EPrayer.fajr => 'fajr',
        EPrayer.sunrise => 'sunrise',
        EPrayer.dhuhr => 'dhuhr',
        EPrayer.asr => 'asr',
        EPrayer.maghrib => 'maghrib',
        EPrayer.isha => 'isha',
      };

  /// Sunrise is shown alongside the prayers but isn't itself a salah —
  /// notifications and adhan must skip it.
  bool get isSalah => this != EPrayer.sunrise;
}

class PrayerSlot {
  const PrayerSlot({required this.prayer, required this.time});
  final EPrayer prayer;
  final DateTime time;
}
