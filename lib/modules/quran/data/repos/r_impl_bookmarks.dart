import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/core/utils/helper/error_helper.dart';
import 'package:quran/modules/quran/data/datasources/local/ds_local_bookmarks.dart';
import 'package:quran/modules/quran/data/models/m_bookmark.dart';
import 'package:quran/modules/quran/data/models/m_last_read.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_bookmarks.dart';
import 'package:uuid/uuid.dart';

class RImplBookmarks implements RBookmarks {
  RImplBookmarks(this._local);
  final DSLocalBookmarks _local;
  final _uuid = const Uuid();

  @override
  Future<Either<Failure, MBookmark>> save({
    required ParamAyahRef ref,
    String? note,
    String? folder,
    String? colorHex,
  }) async {
    try {
      final bookmark = MBookmark(
        id: _uuid.v4(),
        surah: ref.surah,
        ayah: ref.ayah,
        createdAt: DateTime.now(),
        note: note,
        folder: folder,
        colorHex: colorHex,
      );
      await _local.putBookmark(bookmark);
      return Right(bookmark);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplBookmarks.save', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await _local.deleteBookmark(id);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplBookmarks.delete', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MBookmark>>> list() async {
    try {
      final all = _local.listBookmarks()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(all);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplBookmarks.list', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MLastRead?>> getLastRead() async {
    try {
      return Right(_local.getLastRead());
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplBookmarks.getLastRead', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveLastRead(MLastRead value) async {
    try {
      await _local.putLastRead(value);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(name: 'RImplBookmarks.saveLastRead', error: e, stackTrace: st);
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }
}
