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
  static const _verseCharBudget = 85;

  DateTime? _loadedFor;

  /// `0` is the canonical verse of the day; every manual [next] bumps it so a
  /// different ayah is picked. Lives in memory only — a relaunch is back to the
  /// day's verse.
  int _seed = 0;

  Future<void> load() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (state.status == LoadStatus.success && _loadedFor == today) return;
    await _fetch(today);
  }

  /// Replaces the shown verse with another one from the mushaf.
  Future<void> next() async {
    if (state.status == LoadStatus.loading) return;
    final now = DateTime.now();
    _seed++;
    await _fetch(DateTime(now.year, now.month, now.day));
  }

  Future<void> _fetch(DateTime day) async {
    emit(state.copyWith(status: LoadStatus.loading));
    final res = await _getDailyVerse(day, maxChars: _verseCharBudget, seed: _seed);
    res.fold((f) => emit(state.copyWith(status: LoadStatus.error, error: f.message)), (verse) {
      _loadedFor = day;
      emit(state.copyWith(status: LoadStatus.success, verse: verse));
    });
  }
}
