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
      // Upsert: reuse the existing entry's id (and creation date) so recolouring
      // an ayah from the picker replaces it instead of stacking duplicates.
      final existing = _findByAyah(ref);
      final bookmark = MBookmark(
        id: existing?.id ?? _uuid.v4(),
        surah: ref.surah,
        ayah: ref.ayah,
        createdAt: existing?.createdAt ?? DateTime.now(),
        note: note ?? existing?.note,
        folder: folder ?? existing?.folder,
        colorHex: colorHex,
      );
      // A colour holds exactly one verse. The picker asks the user before
      // reassigning one; this is the enforcement, so no entry point can leave
      // two verses sharing a colour.
      await _releaseColor(colorHex, keepId: bookmark.id);
      await _local.putBookmark(bookmark);
      return Right(bookmark);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplBookmarks.save',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    try {
      await _local.deleteBookmark(id);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplBookmarks.delete',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteByAyah(ParamAyahRef ref) async {
    try {
      final existing = _findByAyah(ref);
      if (existing != null) await _local.deleteBookmark(existing.id);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplBookmarks.deleteByAyah',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  /// Deletes every bookmark carrying [colorHex] except [keepId], so the colour
  /// is free for its new owner. Colourless (legacy) bookmarks carry no colour
  /// to release and are left alone.
  Future<void> _releaseColor(String? colorHex, {required String keepId}) async {
    final wanted = _colorKey(colorHex);
    if (wanted == null) return;
    for (final other in _local.listBookmarks()) {
      if (other.id == keepId) continue;
      if (_colorKey(other.colorHex) == wanted) {
        await _local.deleteBookmark(other.id);
      }
    }
  }

  /// Normalised colour so `#EF4444`, `ef4444` and `FFEF4444` all compare equal.
  /// `null` for empty/absent values — those aren't a claim on any colour.
  String? _colorKey(String? hex) {
    if (hex == null || hex.trim().isEmpty) return null;
    var h = hex.replaceFirst('#', '').trim().toUpperCase();
    if (h.length == 8) h = h.substring(2);
    return h;
  }

  /// The stored bookmark on [ref], or `null`. Legacy installs may hold more
  /// than one row per ayah (saving used to always insert); the newest wins and
  /// the rest are cleaned up the next time the ayah is un-bookmarked.
  MBookmark? _findByAyah(ParamAyahRef ref) {
    MBookmark? found;
    for (final b in _local.listBookmarks()) {
      if (b.surah != ref.surah || b.ayah != ref.ayah) continue;
      if (found == null || b.createdAt.isAfter(found.createdAt)) found = b;
    }
    return found;
  }

  @override
  Future<Either<Failure, List<MBookmark>>> list() async {
    try {
      final all = _local.listBookmarks()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(all);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplBookmarks.list',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<MBookmark>> watch() => _local.watchBookmarks();

  @override
  Future<Either<Failure, MLastRead?>> getLastRead() async {
    try {
      return Right(_local.getLastRead());
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplBookmarks.getLastRead',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveLastRead(MLastRead value) async {
    try {
      await _local.putLastRead(value);
      return const Right(null);
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplBookmarks.saveLastRead',
        error: e,
        stackTrace: st,
      );
      return Left(Failure.cacheFailure(message: e.toString()));
    }
  }
}
