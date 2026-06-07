import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quran/core/config/params/params_custom_input.dart';
import 'package:quran/core/theme/brand_colors.dart';
import 'package:quran/core/utils/input_field_validator.dart';
import 'package:quran/core/widgets/forms/base_form_field.dart';
import 'package:quran/core/widgets/forms/w_shared_field.dart';

class WConfirmPasswordField extends BaseFormField {
  WConfirmPasswordField({
    super.isRequired = true,
    super.hint = '',
    super.label = '',
    super.fieldName = '',
    super.icon = Icons.lock_outline_rounded,
    super.validators = const [InputFieldValidator.validatePassword],
  });

  @override
  Widget buildField(BuildContext context, {ParamsCustomInput? param}) {
    bool isObscure = true;
    return StatefulBuilder(
      builder: (context, setState) {
        return WSharedField(
          controller: controller,
          focusNode: focusNode,
          validatorKey: fieldKey,
          hint: hint,
          onValidate: (value) {
            final v1 = param?.confirmPaswordValidation?.call(value);
            if (v1 != null) return v1;
            return validate(value);
          },
          keyboardType: TextInputType.visiblePassword,
          textInputAction: param?.inputAction ?? textInputAction,
          onChanged: param?.onChanged,
          onFieldSubmitted: param?.onFieldSubmitted,
          obscureText: isObscure,
          enabled: param?.enabled ?? true,
          prefixIcon: param?.prefixIcon ?? buildPrefix(),
          suffixIcon: InkWell(
            onTap: () => setState(() => isObscure = !isObscure),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(
                isObscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20.sp,
                color: context.brand.muted,
              ),
            ),
          ),
        );
      },
    );
  }
}
