import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_daily_verse.dart';
import 'package:quran/modules/quran/presentation/cubits/s_daily_verse.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

/// App-wide "verse of the day" cubit. Loads once per calendar day and caches
/// the result for the rest of the session; calling [load] again on the same day
/// is a no-op so it's safe to fire from `initState`.
class CBDailyVerse extends Cubit<SDailyVerse> {
  CBDailyVerse(this._getDailyVerse) : super(const SDailyVerse());

  final UCGetDailyVerse _getDailyVerse;

  /// Max verse length (diacritic-stripped) that fits the home "verse of the
  /// day" card on two lines without ellipsis. Tune here if the card resizes.
  static const _verseCharBudget = 30;

  DateTime? _loadedFor;

  Future<void> load() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (state.status == LoadStatus.success && _loadedFor == today) return;

    emit(state.copyWith(status: LoadStatus.loading));
    final res = await _getDailyVerse(today, maxChars: _verseCharBudget);
    res.fold((f) => emit(state.copyWith(status: LoadStatus.error, error: f.message)), (verse) {
      _loadedFor = today;
      emit(state.copyWith(status: LoadStatus.success, verse: verse));
    });
  }
}
