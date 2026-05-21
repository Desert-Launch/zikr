import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_bookmark.dart';
import 'package:quran/modules/quran/domain/repos/r_bookmarks.dart';

class UCGetBookmarks {
  UCGetBookmarks(this._repo);
  final RBookmarks _repo;

  Future<Either<Failure, List<MBookmark>>> call() => _repo.list();

  Future<Either<Failure, void>> delete(String id) => _repo.delete(id);
}
