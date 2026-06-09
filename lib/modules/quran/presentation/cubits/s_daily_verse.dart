import 'package:equatable/equatable.dart';
import 'package:quran/modules/quran/domain/entities/e_daily_verse.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart'
    show LoadStatus;

class SDailyVerse extends Equatable {
  const SDailyVerse({
    this.status = LoadStatus.idle,
    this.verse,
    this.error,
  });

  final LoadStatus status;
  final EDailyVerse? verse;
  final String? error;

  SDailyVerse copyWith({
    LoadStatus? status,
    EDailyVerse? verse,
    String? error,
    bool clearError = false,
  }) {
    return SDailyVerse(
      status: status ?? this.status,
      verse: verse ?? this.verse,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, verse, error];
}
