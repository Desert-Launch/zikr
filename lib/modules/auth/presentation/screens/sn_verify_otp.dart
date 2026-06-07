import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:localize_and_translate/localize_and_translate.dart';
import 'package:quran/core/config/params/custom_pin_code_options.dart';
import 'package:quran/core/config/params/params_custom_input.dart';
import 'package:quran/core/services/forms/f_otp.dart';
import 'package:quran/core/services/routes/routes_names.dart';
import 'package:quran/core/theme/app_colors.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/modules/auth/presentation/cubits/cb_otp_form.dart';
import 'package:quran/modules/auth/presentation/cubits/s_otp_form.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_button.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_error_banner.dart';
import 'package:quran/modules/auth/presentation/widgets/w_auth_scaffold.dart';

class SNVerifyOtp extends StatefulWidget {
  const SNVerifyOtp({super.key, required this.email});

  final String email;

  @override
  State<SNVerifyOtp> createState() => _SNVerifyOtpState();
}

class _SNVerifyOtpState extends State<SNVerifyOtp> {
  late final CBOtpForm _cubit = Modular.get<CBOtpForm>()
    ..setEmail(widget.email);
  final FOtp _form = FOtp()..init();

  Future<void> _submit() async {
    final ok = await _cubit.verifyOnly();
    if (!mounted) return;
    if (ok) {
      Modular.to.pushNamed(AuthRoutes.fullReset(widget.email, _cubit.state.otp));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: WAuthScaffold(
        title: 'auth_otp_title'.tr(),
        child: BlocBuilder<CBOtpForm, SOtpForm>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'auth_otp_subtitle'.tr().replaceFirst('{{email}}', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.sp, color: context.brand.muted),
                ),
                SizedBox(height: 6.h),
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: AppColorsLight.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 28.h),
                _form.pinCodeField.buildField(
                  context,
                  param: ParamsCustomInput(
                    onChanged: _cubit.setOtp,
                    pinCodeOptions: CustomPinCodeOptions(
                      length: 6,
                      onCompleted: (_) => _submit(),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                if (state.error != null) ...[
                  WAuthErrorBanner(message: state.error!),
                  SizedBox(height: 12.h),
                ],
                WAuthButton(
                  label: 'auth_verify_otp'.tr(),
                  isLoading: state.isSubmitting,
                  onPressed: state.isOtpValid ? _submit : null,
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () => Modular.to.pop(),
                  child: Text(
                    'auth_resend_code'.tr(),
                    style: const TextStyle(
                      color: AppColorsLight.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'auth_demo_otp_hint'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp, color: context.brand.muted),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
