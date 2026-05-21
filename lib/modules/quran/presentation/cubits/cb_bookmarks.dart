import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/usecases/uc_get_bookmarks.dart';
import 'package:quran/modules/quran/domain/usecases/uc_save_bookmark.dart';
import 'package:quran/modules/quran/presentation/cubits/s_bookmarks.dart';
import 'package:quran/modules/quran/presentation/cubits/s_surah_list.dart' show LoadStatus;

class CBBookmarks extends Cubit<SBookmarks> {
  CBBookmarks(this._list, this._save) : super(const SBookmarks());

  final UCGetBookmarks _list;
  final UCSaveBookmark _save;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading));
    final res = await _list();
    res.fold(
      (f) => emit(state.copyWith(status: LoadStatus.error, error: f.message)),
      (all) => emit(state.copyWith(status: LoadStatus.success, all: all)),
    );
  }

  Future<void> add(ParamAyahRef ref, {String? note, String? folder, String? colorHex}) async {
    await _save(ref: ref, note: note, folder: folder, colorHex: colorHex);
    await load();
  }

  Future<void> delete(String id) async {
    await _list.delete(id);
    await load();
  }
}
