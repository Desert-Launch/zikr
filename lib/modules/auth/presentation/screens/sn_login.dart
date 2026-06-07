import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/config/params/params_custom_input.dart';
import 'package:quran/core/services/config/app_config.dart';
import 'package:quran/core/services/forms/f_login.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_login_form.dart';
import 'package:quran/modules/auth/presentation/cubits/s_login_form.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_button.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_error_banner.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_scaffold.dart';

class SNLogin extends StatefulWidget {
  const SNLogin({super.key});

  @override
  State<SNLogin> createState() => _SNLoginState();
}

class _SNLoginState extends State<SNLogin> {
  late final CBLoginForm _cubit = Modular.get<CBLoginForm>();
  final FLogin _form = FLogin()..init();

  Future<void> _submit() async {
    // if (!_form.validate()) return;
    // final ok = await _cubit.submit();
    // if (!mounted) return;
    // if (ok)
    Modular.to.navigate(RoutesNames.homeBase);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WAuthScaffold(
        title: 'auth_login'.tr(),
        subtitle: 'auth_login_subtitle'.tr(),
        child: Form(
          key: _form.formKey,
          child: BlocBuilder<CBLoginForm, SLoginForm>(
            builder: (context, state) {
              _form.emailField.controller.text = 'demo@quran.app';
              _form.passwordField.controller.text = 'P@ssw0rd!';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (AppConfig.useMockBackend) ...[const _DemoCredentials(), SizedBox(height: 16.h)],
                  _form.emailField.buildField(
                    context,
                    param: ParamsCustomInput(onChanged: _cubit.setIdentifier, inputAction: TextInputAction.next),
                  ),
                  SizedBox(height: 14.h),
                  _form.passwordField.buildField(
                    context,
                    param: ParamsCustomInput(onChanged: _cubit.setPassword, onFieldSubmitted: (_) => _submit()),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () => Modular.to.pushNamed(AuthRoutes.fullForgot()),
                      child: Text(
                        'auth_forgot_password'.tr(),
                        style: const TextStyle(color: AppColorsLight.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (state.error != null) ...[WAuthErrorBanner(message: state.error!), SizedBox(height: 12.h)],
                  SizedBox(height: 8.h),
                  WAuthButton(label: 'auth_login'.tr(), isLoading: state.isSubmitting, onPressed: _submit),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth_no_account'.tr(),
                        style: TextStyle(fontSize: 13.sp, color: context.brand.muted),
                      ),
                      TextButton(
                        onPressed: () => Modular.to.pushNamed(AuthRoutes.fullRegister()),
                        child: Text(
                          'auth_register'.tr(),
                          style: const TextStyle(color: AppColorsLight.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
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

class _DemoCredentials extends StatelessWidget {
  const _DemoCredentials();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColorsLight.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColorsLight.accent, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'auth_demo_creds'.tr(),
            style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4.h),
          Text(
            'demo@quran.app  ·  P@ssw0rd!',
            style: TextStyle(fontSize: 11.sp, fontFamily: 'monospace'),
          ),
          Text(
            'test@quran.app  ·  Test1234!',
            style: TextStyle(fontSize: 11.sp, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
