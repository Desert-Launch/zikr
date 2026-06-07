import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/auth/data/models/m_user.dart';
import 'package:quran/modules/auth/domain/entities/e_auth_status.dart';
import 'package:quran/modules/auth/domain/usecases/uc_get_current_user.dart';
import 'package:quran/modules/auth/domain/usecases/uc_is_logged_in.dart';
import 'package:quran/modules/auth/domain/usecases/uc_logout.dart';
import 'package:quran/modules/auth/presentation/cubits/s_auth.dart';

/// App-wide auth state singleton. Lives in [AppModule] DI; consulted at boot
/// by the splash to decide where to route.
class CBAuth extends Cubit<SAuth> {
  CBAuth({
    required UCIsLoggedIn isLoggedIn,
    required UCGetCurrentUser currentUser,
    required UCLogout logout,
  }) : _isLoggedIn = isLoggedIn,
       _currentUser = currentUser,
       _logout = logout,
       super(const SAuth());

  final UCIsLoggedIn _isLoggedIn;
  final UCGetCurrentUser _currentUser;
  final UCLogout _logout;

  Future<void> bootstrap() async {
    final logged = await _isLoggedIn();
    if (!logged) {
      emit(state.copyWith(status: EAuthStatus.loggedOut, clearUser: true));
      return;
    }
    final res = await _currentUser();
    res.fold(
      (_) =>
          emit(state.copyWith(status: EAuthStatus.loggedOut, clearUser: true)),
      (user) => emit(state.copyWith(status: EAuthStatus.loggedIn, user: user)),
    );
  }

  /// Called by the form cubits after a successful login/register.
  void onLoggedIn(MUser user) {
    emit(
      state.copyWith(
        status: EAuthStatus.loggedIn,
        user: user,
        clearError: true,
      ),
    );
  }

  Future<void> logout() async {
    await _logout();
    emit(const SAuth(status: EAuthStatus.loggedOut));
  }
}
