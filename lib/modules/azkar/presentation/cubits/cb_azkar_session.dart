import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/azkar/data/datasources/local/ds_local_azkar.dart';
import 'package:quran/modules/azkar/data/sources/local/box_azkar_progress.dart';
import 'package:quran/modules/azkar/presentation/cubits/s_azkar_session.dart';

/// Per-screen cubit that drives the azkar player: which category we're in,
/// which item is on screen, and how many taps each item has gotten today.
class CBAzkarSession extends Cubit<SAzkarSession> {
  CBAzkarSession({
    required DSLocalAzkar local,
    required BoxAzkarProgress progress,
  }) : _local = local,
       _progress = progress,
       super(const SAzkarSession());

  final DSLocalAzkar _local;
  final BoxAzkarProgress _progress;

  Future<void> open(String categoryId) async {
    final cat = await _local.category(categoryId);
    if (cat == null) return;
    final stored = _progress.today(categoryId);
    emit(
      state.copyWith(
        category: cat,
        itemIndex: 0,
        completed: Map<String, int>.from(stored.completedCounts),
      ),
    );
  }

  Future<void> tap() async {
    final item = state.currentItem;
    final cat = state.category;
    if (item == null || cat == null) return;
    if (state.isComplete(item)) {
      next();
      return;
    }
    final updated = Map<String, int>.from(state.completed);
    updated[item.id] = (updated[item.id] ?? 0) + 1;
    emit(state.copyWith(completed: updated));
    await _progress.increment(cat.id, item.id);
  }

  void next() {
    final cat = state.category;
    if (cat == null) return;
    final ni = (state.itemIndex + 1).clamp(0, cat.items.length - 1);
    emit(state.copyWith(itemIndex: ni));
  }

  void previous() {
    final cat = state.category;
    if (cat == null) return;
    final pi = (state.itemIndex - 1).clamp(0, cat.items.length - 1);
    emit(state.copyWith(itemIndex: pi));
  }

  void jumpTo(int index) {
    final cat = state.category;
    if (cat == null) return;
    emit(state.copyWith(itemIndex: index.clamp(0, cat.items.length - 1)));
  }

  Future<void> resetCategory() async {
    final cat = state.category;
    if (cat == null) return;
    await _progress.reset(cat.id);
    emit(state.copyWith(completed: <String, int>{}, itemIndex: 0));
  }

  Future<void> resetCurrent() async {
    final cat = state.category;
    final item = state.currentItem;
    if (cat == null || item == null) return;
    await _progress.resetItem(cat.id, item.id);
    final updated = Map<String, int>.from(state.completed)..remove(item.id);
    emit(state.copyWith(completed: updated));
  }
}
