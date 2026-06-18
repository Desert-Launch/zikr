import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/data/models/m_page_layout.dart';
import 'package:quran/modules/quran/domain/entities/e_quran_font_mode.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';

class UCGetPageLayout {
  UCGetPageLayout(this._repo);
  final RQuran _repo;

  Future<Either<Failure, MPageLayout>> call(
    int page, {
    EQuranFontMode mode = EQuranFontMode.plainV1,
  }) =>
      _repo.getPage(page, mode: mode);
}
