import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_bookmark.dart';
import 'package:quran/modules/quran/data/models/m_last_read.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';

abstract class RBookmarks {
  Future<Either<Failure, MBookmark>> save({
    required ParamAyahRef ref,
    String? note,
    String? folder,
    String? colorHex,
  });
  Future<Either<Failure, void>> delete(String id);
  Future<Either<Failure, List<MBookmark>>> list();
  Future<Either<Failure, MLastRead?>> getLastRead();
  Future<Either<Failure, void>> saveLastRead(MLastRead value);
}
