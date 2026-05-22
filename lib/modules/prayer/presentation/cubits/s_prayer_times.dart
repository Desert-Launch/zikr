import 'package:equatable/equatable.dart';
import 'package:quran/modules/prayer/domain/entities/e_prayer.dart';

enum PrayerLoadStatus { idle, loading, success, error, permissionDenied }

class SPrayerTimes extends Equatable {
  const SPrayerTimes({
    this.status = PrayerLoadStatus.idle,
    this.slots = const [],
    this.cityName = '',
    this.latitude,
    this.longitude,
    this.computedAt,
    this.error,
  });

  final PrayerLoadStatus status;
  final List<PrayerSlot> slots;
  final String cityName;
  final double? latitude;
  final double? longitude;
  final DateTime? computedAt;
  final String? error;

  /// Returns the next future prayer (sunrise excluded since you don't pray it).
  PrayerSlot? get nextPrayer {
    final now = DateTime.now();
    for (final s in slots) {
      if (s.prayer == EPrayer.sunrise) continue;
      if (s.time.isAfter(now)) return s;
    }
    return null;
  }

  /// Returns the salah whose window the user is currently inside (most-recent
  /// past salah). Null before fajr.
  PrayerSlot? get currentSalah {
    final now = DateTime.now();
    PrayerSlot? hit;
    for (final s in slots) {
      if (s.prayer == EPrayer.sunrise) continue;
      if (s.time.isBefore(now) || s.time.isAtSameMomentAs(now)) hit = s;
    }
    return hit;
  }

  SPrayerTimes copyWith({
    PrayerLoadStatus? status,
    List<PrayerSlot>? slots,
    String? cityName,
    double? latitude,
    double? longitude,
    DateTime? computedAt,
    String? error,
    bool clearError = false,
  }) {
    return SPrayerTimes(
      status: status ?? this.status,
      slots: slots ?? this.slots,
      cityName: cityName ?? this.cityName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      computedAt: computedAt ?? this.computedAt,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [status, slots, cityName, latitude, longitude, computedAt, error];
}
