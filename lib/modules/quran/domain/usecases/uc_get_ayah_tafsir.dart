import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/e_tafsir_entry.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_tafsir.dart';

class UCGetAyahTafsir {
  UCGetAyahTafsir(this._repo);
  final RTafsir _repo;

  Future<Either<Failure, List<ETafsirEntry>>> call(ParamAyahRef ref) =>
      _repo.getForAyah(ref);
}
