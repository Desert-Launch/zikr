import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/modules/auth/domain/entities/param_reset.dart';
import 'package:quran/modules/auth/domain/usecases/uc_reset_password.dart';
import 'package:quran/modules/auth/domain/usecases/uc_verify_otp.dart';
import 'package:quran/modules/auth/presentation/cubits/s_otp_form.dart';

class CBOtpForm extends Cubit<SOtpForm> {
  CBOtpForm({required UCVerifyOtp verify, required UCResetPassword reset})
    : _verify = verify,
      _reset = reset,
      super(const SOtpForm());

  final UCVerifyOtp _verify;
  final UCResetPassword _reset;
  String email = '';

  void setEmail(String value) {
    email = value;
  }

  void setOtp(String v) => emit(state.copyWith(otp: v, clearError: true));
  void setPassword(String v) =>
      emit(state.copyWith(newPassword: v, clearError: true));
  void setConfirmPassword(String v) =>
      emit(state.copyWith(confirmPassword: v, clearError: true));
  void toggleObscure() =>
      emit(state.copyWith(obscurePassword: !state.obscurePassword));

  /// Verifies the OTP without resetting the password. Used by SNVerifyOtp.
  Future<bool> verifyOnly() async {
    if (!state.isOtpValid) return false;
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final res = await _verify(email: email, otp: state.otp);
    return res.fold(
      (f) {
        emit(state.copyWith(isSubmitting: false, error: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(isSubmitting: false));
        return true;
      },
    );
  }

  Future<bool> resetPassword() async {
    if (!state.isValid) return false;
    emit(state.copyWith(isSubmitting: true, clearError: true));
    final res = await _reset(
      ParamReset(email: email, otp: state.otp, newPassword: state.newPassword),
    );
    return res.fold(
      (f) {
        emit(state.copyWith(isSubmitting: false, error: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(isSubmitting: false, didReset: true));
        return true;
      },
    );
  }
}
