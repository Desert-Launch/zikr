import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/config/params/params_custom_input.dart';
import 'package:quran/core/services/forms/f_register.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_register_form.dart';
import 'package:quran/modules/auth/presentation/cubits/s_register_form.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_button.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_error_banner.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_scaffold.dart';

class SNRegister extends StatefulWidget {
  const SNRegister({super.key});

  @override
  State<SNRegister> createState() => _SNRegisterState();
}

class _SNRegisterState extends State<SNRegister> {
  late final CBRegisterForm _cubit = Modular.get<CBRegisterForm>();
  final FRegister _form = FRegister()..init();

  Future<void> _submit() async {
    if (!_form.validate()) return;
    final ok = await _cubit.submit();
    if (!mounted) return;
    if (ok) Modular.to.pushNamed(AuthRoutes.fullSuccess());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WAuthScaffold(
        title: 'auth_register'.tr(),
        subtitle: 'auth_register_subtitle'.tr(),
        child: Form(
          key: _form.formKey,
          child: BlocBuilder<CBRegisterForm, SRegisterForm>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _form.nameField.buildField(
                    context,
                    param: ParamsCustomInput(
                      onChanged: _cubit.setName,
                      inputAction: TextInputAction.next,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  _form.birthDateField.buildField(
                    context,
                    param: ParamsCustomInput(onChanged: _cubit.setBirthDate),
                  ),
                  SizedBox(height: 14.h),
                  _form.emailField.buildField(
                    context,
                    param: ParamsCustomInput(
                      onChanged: _cubit.setEmail,
                      inputAction: TextInputAction.next,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  _form.phoneField.buildField(
                    context,
                    param: ParamsCustomInput(
                      onChanged: _cubit.setPhone,
                      inputAction: TextInputAction.next,
                    ),
                  ),
                  SizedBox(height: 14.h),
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
                    label: 'auth_register'.tr(),
                    isLoading: state.isSubmitting,
                    onPressed: _submit,
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth_have_account'.tr(),
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: context.brand.muted,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Modular.to.pop(),
                        child: Text(
                          'auth_login'.tr(),
                          style: const TextStyle(
                            color: AppColorsLight.primary,
                            fontWeight: FontWeight.w700,
                          ),
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
