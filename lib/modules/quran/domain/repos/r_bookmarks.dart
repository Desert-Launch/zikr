import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_bookmark.dart';
import 'package:quran/modules/quran/data/models/m_last_read.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

abstract class RBookmarks {
  /// Upserts the bookmark for [ref]: an ayah has at most one bookmark, so
  /// saving an already-bookmarked verse recolours it in place instead of
  /// stacking a duplicate entry.
  Future<Either<Failure, MBookmark>> save({
    required ParamAyahRef ref,
    String? note,
    String? folder,
    String? colorHex,
  });
  Future<Either<Failure, void>> delete(String id);

  /// Removes the bookmark on [ref], if any. Used by the reader's toggle, which
  /// knows the ayah but not the generated bookmark id.
  Future<Either<Failure, void>> deleteByAyah(ParamAyahRef ref);
  Future<Either<Failure, List<MBookmark>>> list();

  /// Emits the bookmark list on every change (add/update/delete).
  Stream<List<MBookmark>> watch();
  Future<Either<Failure, MLastRead?>> getLastRead();
  Future<Either<Failure, void>> saveLastRead(MLastRead value);
}
