import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/config/params/params_custom_input.dart';
import 'package:quran/core/services/forms/f_forget_password.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_forgot_form.dart';
import 'package:quran/modules/auth/presentation/cubits/s_forgot_form.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_button.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_error_banner.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_scaffold.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_success_banner.dart';

class SNForgotPassword extends StatefulWidget {
  const SNForgotPassword({super.key});

  @override
  State<SNForgotPassword> createState() => _SNForgotPasswordState();
}

class _SNForgotPasswordState extends State<SNForgotPassword> {
  late final CBForgotForm _cubit = Modular.get<CBForgotForm>();
  final FForgetPassword _form = FForgetPassword();

  Future<void> _submit() async {
    if (!_form.validate()) return;
    final ok = await _cubit.submit();
    if (!mounted) return;
    if (ok) Modular.to.pushNamed(AuthRoutes.fullOtp(_cubit.state.email.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WAuthScaffold(
        title: 'auth_forgot_title'.tr(),
        subtitle: 'auth_forgot_subtitle'.tr(),
        child: Form(
          key: _form.formKey,
          child: BlocBuilder<CBForgotForm, SForgotForm>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _form.emailField.buildField(
                    context,
                    param: ParamsCustomInput(
                      onChanged: _cubit.setEmail,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  if (state.error != null) ...[
                    WAuthErrorBanner(message: state.error!),
                    SizedBox(height: 12.h),
                  ],
                  if (state.didSend) ...[
                    WAuthSuccessBanner(message: 'auth_otp_sent'.tr()),
                    SizedBox(height: 12.h),
                  ],
                  WAuthButton(
                    label: 'auth_send_reset_link'.tr(),
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
