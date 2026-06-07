import 'package:flutter_modular/flutter_modular.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/auth/domain/repos/r_auth.dart';
import 'package:quran/modules/auth/domain/usecases/uc_forgot_password.dart';
import 'package:quran/modules/auth/domain/usecases/uc_login.dart';
import 'package:quran/modules/auth/domain/usecases/uc_register.dart';
import 'package:quran/modules/auth/domain/usecases/uc_reset_password.dart';
import 'package:quran/modules/auth/domain/usecases/uc_verify_otp.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_auth.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_forgot_form.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_login_form.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_otp_form.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_register_form.dart';
import 'package:quran/modules/auth/presentation/screens/sn_forgot_password.dart';
import 'package:quran/modules/auth/presentation/screens/sn_login.dart';
import 'package:quran/modules/auth/presentation/screens/sn_register.dart';
import 'package:quran/modules/auth/presentation/screens/sn_register_success.dart';
import 'package:quran/modules/auth/presentation/screens/sn_reset_password.dart';
import 'package:quran/modules/auth/presentation/screens/sn_verify_otp.dart';

/// Form-screen scope. The data layer (RAuth, DS, boxes) and the singletons
/// CBAuth needs at boot live in [AppModule]; this submodule only binds
/// per-screen form use cases and cubits.
///
/// Cross-module lookups use `Modular.get<T>()` rather than the local `i.get<T>()`
/// because the local injector here doesn't traverse up into AppModule's
/// bindings.
class AuthModule extends Module {
  @override
  void binds(Injector i) {
    // Use cases that only the form screens need. RAuth lives in AppModule.
    i.add<UCLogin>(() => UCLogin(Modular.get<RAuth>()));
    i.add<UCRegister>(() => UCRegister(Modular.get<RAuth>()));
    i.add<UCForgotPassword>(() => UCForgotPassword(Modular.get<RAuth>()));
    i.add<UCVerifyOtp>(() => UCVerifyOtp(Modular.get<RAuth>()));
    i.add<UCResetPassword>(() => UCResetPassword(Modular.get<RAuth>()));

    // Per-screen form cubits (factory). CBAuth lives in AppModule.
    i.add<CBLoginForm>(
      () => CBLoginForm(Modular.get<UCLogin>(), Modular.get<CBAuth>()),
    );
    i.add<CBRegisterForm>(
      () => CBRegisterForm(Modular.get<UCRegister>(), Modular.get<CBAuth>()),
    );
    i.add<CBForgotForm>(() => CBForgotForm(Modular.get<UCForgotPassword>()));
    i.add<CBOtpForm>(
      () => CBOtpForm(
        verify: Modular.get<UCVerifyOtp>(),
        reset: Modular.get<UCResetPassword>(),
      ),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(AuthRoutes.login, child: (_) => const SNLogin());
    r.child(AuthRoutes.register, child: (_) => const SNRegister());
    r.child(AuthRoutes.forgotPassword, child: (_) => const SNForgotPassword());
    r.child(
      AuthRoutes.verifyOtp,
      child: (_) {
        final email = r.args.queryParams['email'] ?? '';
        return SNVerifyOtp(email: email);
      },
    );
    r.child(
      AuthRoutes.resetPassword,
      child: (_) {
        final email = r.args.queryParams['email'] ?? '';
        final otp = r.args.queryParams['otp'] ?? '';
        return SNResetPassword(email: email, otp: otp);
      },
    );
    r.child(
      AuthRoutes.registerSuccess,
      child: (_) => const SNRegisterSuccess(),
    );
  }
}
