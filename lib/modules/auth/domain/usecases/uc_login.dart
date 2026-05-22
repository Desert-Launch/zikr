import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/auth/domain/entities/param_login.dart';
import 'package:quran/modules/auth/domain/repos/r_auth.dart';

class UCLogin {
  UCLogin(this._repo);
  final RAuth _repo;

  Future<Either<Failure, AuthSuccess>> call(ParamLogin p) => _repo.login(p);
}
