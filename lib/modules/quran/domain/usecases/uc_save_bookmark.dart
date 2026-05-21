import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_bookmark.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_bookmarks.dart';

class UCSaveBookmark {
  UCSaveBookmark(this._repo);
  final RBookmarks _repo;

  Future<Either<Failure, MBookmark>> call({
    required ParamAyahRef ref,
    String? note,
    String? folder,
    String? colorHex,
  }) {
    return _repo.save(ref: ref, note: note, folder: folder, colorHex: colorHex);
  }
}
