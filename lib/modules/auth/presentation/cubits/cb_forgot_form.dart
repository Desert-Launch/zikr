import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/auth/domain/usecases/uc_forgot_password.dart';
import 'package:quran/modules/auth/presentation/cubits/s_forgot_form.dart';

class CBForgotForm extends Cubit<SForgotForm> {
  CBForgotForm(this._forgot) : super(const SForgotForm());

  final UCForgotPassword _forgot;

  void setEmail(String v) =>
      emit(state.copyWith(email: v, clearError: true, didSend: false));

  Future<bool> submit() async {
    if (!state.isValid) return false;
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final res = await _forgot(state.email.trim());
    return res.fold(
      (f) {
        emit(state.copyWith(isSubmitting: false, error: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(isSubmitting: false, didSend: true));
        return true;
      },
    );
  }
}
