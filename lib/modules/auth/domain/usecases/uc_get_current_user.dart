import 'package:dartz/dartz.dart';
import 'package:quran/core/errors/failure.dart';
import 'package:quran/modules/auth/data/models/m_user.dart';
import 'package:quran/modules/auth/domain/repos/r_auth.dart';

class UCGetCurrentUser {
  UCGetCurrentUser(this._repo);
  final RAuth _repo;

  Future<Either<Failure, MUser>> call() => _repo.currentUser();
}
