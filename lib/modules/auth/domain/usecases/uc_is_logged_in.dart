import 'package:quran/modules/auth/domain/repos/r_auth.dart';

class UCIsLoggedIn {
  UCIsLoggedIn(this._repo);
  final RAuth _repo;

  Future<bool> call() => _repo.isLoggedIn();
}
