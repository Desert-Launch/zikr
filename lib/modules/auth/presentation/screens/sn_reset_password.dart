import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/config/params/params_custom_input.dart';
import 'package:quran/core/services/forms/f_reset_password.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_otp_form.dart';
import 'package:quran/modules/auth/presentation/cubits/s_otp_form.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_button.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_error_banner.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_scaffold.dart';

class SNResetPassword extends StatefulWidget {
  const SNResetPassword({super.key, required this.email, required this.otp});

  final String email;
  final String otp;

  @override
  State<SNResetPassword> createState() => _SNResetPasswordState();
}

class _SNResetPasswordState extends State<SNResetPassword> {
  late final CBOtpForm _cubit = Modular.get<CBOtpForm>()
    ..setEmail(widget.email)
    ..setOtp(widget.otp);
  final FResetPassword _form = FResetPassword()..init();

  Future<void> _submit() async {
    if (!_form.validate()) return;
    final ok = await _cubit.resetPassword();
    if (!mounted) return;
    if (ok) Modular.to.navigate(AuthRoutes.fullLogin());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WAuthScaffold(
        title: 'auth_reset_title'.tr(),
        subtitle: 'auth_reset_subtitle'.tr(),
        child: Form(
          key: _form.formKey,
          child: BlocBuilder<CBOtpForm, SOtpForm>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _form.passwordField.buildField(
                    context,
                    param: ParamsCustomInput(
                      onChanged: _cubit.setPassword,
                      inputAction: TextInputAction.next,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  _form.confirmPasswordField.buildField(
                    context,
                    param: ParamsCustomInput(
                      onChanged: _cubit.setConfirmPassword,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  if (state.error != null) ...[
                    WAuthErrorBanner(message: state.error!),
                    SizedBox(height: 12.h),
                  ],
                  WAuthButton(
                    label: 'auth_reset_button'.tr(),
                    isLoading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
