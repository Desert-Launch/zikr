import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/auth/domain/entities/param_register.dart';
import 'package:quran/modules/auth/domain/usecases/uc_register.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_auth.dart';
import 'package:quran/modules/auth/presentation/cubits/s_register_form.dart';

class CBRegisterForm extends Cubit<SRegisterForm> {
  CBRegisterForm(this._register, this._auth) : super(const SRegisterForm());

  final UCRegister _register;
  final CBAuth _auth;

  void setName(String v) => emit(state.copyWith(name: v, clearError: true));
  void setEmail(String v) => emit(state.copyWith(email: v, clearError: true));
  void setPhone(String v) => emit(state.copyWith(phone: v, clearError: true));
  void setPassword(String v) => emit(state.copyWith(password: v, clearError: true));
  void setConfirmPassword(String v) =>
      emit(state.copyWith(confirmPassword: v, clearError: true));
  void toggleObscure() =>
      emit(state.copyWith(obscurePassword: !state.obscurePassword));

  Future<bool> submit() async {
    if (!state.isValid) return false;
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final res = await _register(ParamRegister(
      name: state.name.trim(),
      email: state.email.trim(),
      phone: state.phone.replaceAll(' ', ''),
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
