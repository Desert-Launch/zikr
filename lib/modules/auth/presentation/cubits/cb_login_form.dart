import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/auth/domain/entities/param_login.dart';
import 'package:quran/modules/auth/domain/usecases/uc_login.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_auth.dart';
import 'package:quran/modules/auth/presentation/cubits/s_login_form.dart';

class CBLoginForm extends Cubit<SLoginForm> {
  CBLoginForm(this._login, this._auth) : super(const SLoginForm());

  final UCLogin _login;
  final CBAuth _auth;

  void setIdentifier(String v) => emit(state.copyWith(identifier: v, clearError: true));
  void setPassword(String v) => emit(state.copyWith(password: v, clearError: true));
  void toggleObscure() =>
      emit(state.copyWith(obscurePassword: !state.obscurePassword));

  Future<bool> submit() async {
    if (!state.isValid) return false;
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final res = await _login(ParamLogin(
      identifier: state.identifier.trim(),
      password: state.password,
    ));
    return res.fold(
      (f) {
        emit(state.copyWith(isSubmitting: false, error: f.message));
        return false;
      },
      (success) {
        _auth.onLoggedIn(success.user);
        emit(state.copyWith(isSubmitting: false));
        return true;
      },
    );
  }
}
