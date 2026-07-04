import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_qpc_v4_page.dart';
import 'package:quran/modules/quran/domain/repos/r_quran_v4.dart';

class UCGetQpcV4Page {
  UCGetQpcV4Page(this._repo);
  final RQuranV4 _repo;

  Future<Either<Failure, MQpcV4Page>> call(int page) => _repo.getPage(page);
}
