import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/quran/domain/entities/param_ayah_ref.dart';
import 'package:quran/modules/quran/domain/repos/r_quran.dart';

class SearchHit extends Equatable {
  const SearchHit({required this.ref, required this.snippet});
  final ParamAyahRef ref;
  final String snippet;
  @override
  List<Object?> get props => [ref];
}

class UCSearchQuran {
  UCSearchQuran(this.repo);
  // ignore: public_member_api_docs — used by Phase 12 implementation.
  final RQuran repo;

  Future<Either<Failure, List<SearchHit>>> call(String query) async {
    // Placeholder — Phase 12 wires the actual normalized text index over `repo`.
    if (query.trim().isEmpty) return const Right([]);
    return const Right([]);
  }
}
